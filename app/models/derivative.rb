# frozen_string_literal: true

# Represents a derivative financial instrument tied to an underlying asset.
class Derivative < ApplicationRecord
  # Associations
  belongs_to :instrument
  has_many :margin_requirements, as: :requirementable, dependent: :destroy
  has_many :order_features, as: :featureable, dependent: :destroy

  enum :exchange, {
    nse: 'NSE',
    bse: 'BSE',
    mcx: 'MCX'
  }

  enum :segment, {
    index: 'I',
    equity: 'E',
    currency: 'C',
    derivatives: 'D',
    commodity: 'M'
  }, prefix: true

  enum :instrument, {
    index: 'INDEX',
    futures_index: 'FUTIDX',
    options_index: 'OPTIDX',
    equity: 'EQUITY',
    futures_stock: 'FUTSTK',
    options_stock: 'OPTSTK',
    futures_currency: 'FUTCUR',
    options_currency: 'OPTCUR',
    futures_commodity: 'FUTCOM',
    options_commodity: 'OPTFUT'
  }, prefix: true

  # Validations
  validates :strike_price, :option_type, :expiry_date, presence: true

  def ltp
    response = DhanHQ::Models::MarketFeed.ltp(exch_segment_enum)
    response['status'] == 'success' ? response.dig('data', exchange_segment, security_id.to_s, 'last_price') : nil
  rescue StandardError => e
    Rails.logger.error("Failed to fetch LTP for Derivative #{security_id}: #{e.message}")
    nil
  end

  def ohlc
    response = DhanHQ::Models::MarketFeed.ohlc(exch_segment_enum)
    response['status'] == 'success' ? response.dig('data', exchange_segment, security_id.to_s) : nil
  rescue StandardError => e
    Rails.logger.error("Failed to fetch OHLC for Derivative #{security_id}: #{e.message}")
    nil
  end

  def depth
    response = DhanHQ::Models::MarketFeed.quote(exch_segment_enum)
    response['status'] == 'success' ? response.dig('data', exchange_segment, security_id.to_s) : nil
  rescue StandardError => e
    Rails.logger.error("Failed to fetch Depth for Derivative #{security_id}: #{e.message}")
    nil
  end

  # Generate `exchange_segment` dynamically
  def exchange_segment
    case [exchange.to_sym, segment.to_sym]
    when %i[nse index], %i[bse index] then 'IDX_I'
    when %i[nse equity] then 'NSE_EQ'
    when %i[bse equity] then 'BSE_EQ'
    when %i[nse derivatives] then 'NSE_FNO'
    when %i[bse derivatives] then 'BSE_FNO'
    when %i[nse currency] then 'NSE_CURRENCY'
    when %i[bse currency] then 'BSE_CURRENCY'
    when %i[mcx commodity] then 'MCX_COMM'
    else
      raise "Unsupported exchange and segment combination: #{exchange}, #{segment}"
    end
  end

  private

  def exch_segment_enum
    { exchange_segment => [security_id.to_i] }
  end
end
