require 'csv'
require 'open-uri'

URL   = 'https://images.dhan.co/api-data/api-scrip-master-detailed.csv'.freeze
CACHE = Rails.root.join('tmp/dhan.csv')

# download only if file is missing or > 12 h old
if !File.exist?(CACHE) || (Time.zone.now - CACHE.mtime) > 12.hours
  puts 'Downloading CSV …'
  File.binwrite(CACHE, URI.open(URL).read)
else
  puts "Using cached CSV (#{((Time.zone.now - CACHE.mtime) / 3600).round(1)} h old)"
end

rows = CSV.read(CACHE, headers: true)
puts "Loaded #{rows.size} rows"

EXCH_OK   = %w[NSE BSE MCX].freeze
SPOT_CODE = %w[INDEX EQUITY].freeze

referenced_ids = rows.filter_map { |r| r['UNDERLYING_SECURITY_ID'] }.to_set

spot_attrs =
  rows.filter_map do |r|
    next unless EXCH_OK.include?(r['EXCH_ID'])
    next unless referenced_ids.include?(r['SECURITY_ID']) ||
                SPOT_CODE.include?(r['INSTRUMENT'])

    {
      security_id: r['SECURITY_ID'],
      exchange: r['EXCH_ID'],
      segment: r['SEGMENT'],
      symbol_name: r['SYMBOL_NAME'],
      display_name: r['DISPLAY_NAME'],
      isin: r['ISIN'],
      instrument: r['INSTRUMENT'],
      instrument_type: r['INSTRUMENT_TYPE'],
      underlying_symbol: r['UNDERLYING_SYMBOL'],
      underlying_security_id: r['UNDERLYING_SECURITY_ID'],
      series: r['SERIES'],
      lot_size: (n = r['LOT_SIZE'].to_i).positive? ? n : nil,
      tick_size: r['TICK_SIZE'],
      asm_gsm_flag: r['ASM_GSM_FLAG'],
      asm_gsm_category: r['ASM_GSM_CATEGORY'],
      mtf_leverage: r['MTF_LEVERAGE'],
      created_at: Time.current,
      updated_at: Time.current
    }
  end

Instrument.delete_all # start clean each time
Instrument.import spot_attrs, validate: false, batch_size: 1_000
puts "Inserted #{Instrument.count} instruments"

instrument_lookup =
  Instrument.pluck(:id, :underlying_symbol, :exchange).each_with_object({}) do |(id, sym, ex), h|
    h["#{sym}-#{ex}"] = id
  end
puts "Lookup table ready (#{instrument_lookup.size} keys)"

DERIV_CODE = %w[FUTIDX OPTIDX FUTSTK OPTSTK FUTCUR OPTCUR FUTCOM OPTFUT].freeze

deriv_attrs =
  rows.filter_map do |r|
    next unless EXCH_OK.include?(r['EXCH_ID'])
    next unless r['SEGMENT'] == 'D' && DERIV_CODE.include?(r['INSTRUMENT'])

    inst_id = instrument_lookup["#{r['UNDERLYING_SYMBOL']}-#{r['EXCH_ID']}"]
    next unless inst_id # skip orphans

    {
      instrument_id: inst_id,
      exchange: r['EXCH_ID'],
      segment: r['SEGMENT'],
      security_id: r['SECURITY_ID'],
      symbol_name: r['SYMBOL_NAME'],
      display_name: r['DISPLAY_NAME'],
      instrument: r['INSTRUMENT'],
      instrument_type: r['INSTRUMENT_TYPE'],
      underlying_symbol: r['UNDERLYING_SYMBOL'],
      underlying_security_id: r['UNDERLYING_SECURITY_ID'],
      expiry_date: begin
        Date.parse(r['SM_EXPIRY_DATE'])
      rescue StandardError
        nil
      end,
      strike_price: r['STRIKE_PRICE'],
      option_type: r['OPTION_TYPE'],
      expiry_flag: r['EXPIRY_FLAG'],
      lot_size: r['LOT_SIZE'].to_i,
      tick_size: r['TICK_SIZE'],
      asm_gsm_flag: r['ASM_GSM_FLAG'] == 'Y',
      created_at: Time.current,
      updated_at: Time.current
    }
  end

Derivative.delete_all
Derivative.import deriv_attrs, validate: false, batch_size: 1_000
puts "Inserted #{Derivative.count} derivatives"

puts 'Done!'