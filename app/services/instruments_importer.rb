# frozen_string_literal: true

require 'csv'
require 'open-uri'

class InstrumentsImporter
  CSV_URL  = 'https://images.dhan.co/api-data/api-scrip-master-detailed.csv'
  CACHE    = Rails.root.join('tmp/api-scrip-master-detailed.csv')

  VALID_EXCHANGES   = %w[NSE BSE MCX].freeze
  SPOT_CODES        = %w[INDEX EQUITY].freeze
  DERIV_CODES       = %w[FUTIDX OPTIDX FUTSTK OPTSTK FUTCUR OPTCUR FUTCOM OPTFUT].freeze
  BATCH_SIZE        = 1_000 # activerecord-import takes care of slicing

  # ------------------------------------------------------------------------
  def self.import(path = nil)
    path ||= fetch_csv
    csv  = CSV.read(path, headers: true)
    Rails.logger.info "CSV loaded – #{csv.size} rows"

    spots, derivs = partition_rows(csv)

    import_spots(spots)
    import_derivs(derivs)

    Rails.logger.info '✓ CSV import finished'
  end

  # ------------------------------------------------------------------------
  # cache logic
  # ------------------------------------------------------------------------
  def self.fetch_csv
    if !File.exist?(CACHE) || (Time.zone.now - CACHE.mtime) > 12.hours
      Rails.logger.info 'Downloading master CSV …'
      File.binwrite(CACHE, URI.open(CSV_URL).read)
    else
      age = ((Time.zone.now - CACHE.mtime) / 3600).round(1)
      Rails.logger.info "Using cached CSV (#{age} h old)"
    end
    CACHE
  end

  # ------------------------------------------------------------------------
  # split into spot & derivative attribute hashes
  # ------------------------------------------------------------------------
  def self.partition_rows(csv)
    referenced = csv.pluck('UNDERLYING_SECURITY_ID').compact.to_set

    spot_attrs   = []
    deriv_attrs  = []

    csv.each do |r|
      next unless VALID_EXCHANGES.include?(r['EXCH_ID'])

      attrs = build_common_attrs(r)

      if SPOT_CODES.include?(r['INSTRUMENT']) ||
         referenced.include?(r['SECURITY_ID'])
        spot_attrs << attrs
      elsif DERIV_CODES.include?(r['INSTRUMENT'])
        deriv_attrs << attrs.merge(
          expiry_date: safe_date(r['SM_EXPIRY_DATE']),
          strike_price: r['STRIKE_PRICE'],
          option_type: r['OPTION_TYPE'],
          expiry_flag: r['EXPIRY_FLAG'],
          asm_gsm_flag: r['ASM_GSM_FLAG'] == 'Y'
        )
      end
    end
    [spot_attrs, deriv_attrs]
  end

  # ------------------------------------------------------------------------
  def self.build_common_attrs(r)
    {
      security_id: r['SECURITY_ID'],
      exchange: r['EXCH_ID'],
      segment: r['SEGMENT'],
      instrument: r['INSTRUMENT'],
      instrument_type: r['INSTRUMENT_TYPE'],
      symbol_name: r['SYMBOL_NAME'],
      display_name: r['DISPLAY_NAME'],
      isin: r['ISIN'] || 0,
      underlying_symbol: r['UNDERLYING_SYMBOL'],
      underlying_security_id: r['UNDERLYING_SECURITY_ID'],
      series: r['SERIES'],
      lot_size: safe_int(r['LOT_SIZE']),
      tick_size: r['TICK_SIZE'],
      asm_gsm_flag: r['ASM_GSM_FLAG'],
      asm_gsm_category: r['ASM_GSM_CATEGORY'],
      mtf_leverage: r['MTF_LEVERAGE'],
      created_at: Time.current,
      updated_at: Time.current
    }
  end

  # ------------------------------------------------------------------------
  # import spots → instruments
  # ------------------------------------------------------------------------
  def self.import_spots(attrs)
    Instrument.delete_all

    Instrument.import attrs,
                      validate: false,
                      batch_size: BATCH_SIZE,
                      on_duplicate_key_update: {
                        conflict_target: %i[security_id symbol_name exchange segment],
                        columns: %i[display_name isin instrument_type
                                    underlying_symbol underlying_security_id
                                    lot_size tick_size asm_gsm_flag
                                    asm_gsm_category mtf_leverage updated_at]
                      }

    Rails.logger.info "• #{Instrument.count} instruments imported"
  end

  # ------------------------------------------------------------------------
  # import derivs → derivatives (FK uses underlying_security_id)
  # ------------------------------------------------------------------------
  def self.import_derivs(attrs)
    # lookup: security_id → instrument.id
    id_map = Instrument.pluck(:security_id, :id).to_h

    attrs.each { |h| h[:instrument_id] = id_map[h[:underlying_security_id]] }
    attrs.select! { |h| h[:instrument_id].present? } # drop orphans

    Derivative.delete_all
    Derivative.import attrs,
                      validate: false,
                      batch_size: BATCH_SIZE,
                      on_duplicate_key_update: {
                        conflict_target: %i[security_id symbol_name exchange segment],
                        columns: %i[display_name instrument_type
                                    underlying_symbol lot_size tick_size
                                    expiry_date strike_price option_type
                                    expiry_flag asm_gsm_flag instrument_id
                                    updated_at]
                      }

    Rails.logger.info "• #{Derivative.count} derivatives imported"
  end

  # helpers ----------------------------------------------------------------
  def self.safe_int(v)
    n = v.to_i
    n.positive? ? n : nil
  end

  def self.safe_date(s)
    Date.parse(s)
  rescue StandardError
    nil
  end
end
