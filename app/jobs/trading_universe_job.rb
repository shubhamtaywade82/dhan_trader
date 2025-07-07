# app/jobs/trading_universe_job.rb
class TradingUniverseJob < ApplicationJob
  queue_as :default

  AVG_VOLUME_MIN = 1_000_000
  ATR_PERCENT_MIN = 0.01 # 1%
  ADX_MIN = 20

  def perform
    Instrument.update_all(tradable: false) # rubocop:disable Rails/SkipsModelValidations

    candidates = Instrument.segment_equity

    candidates.find_each(batch_size: 50) do |instrument|
      sleep(0.1)
      candles = fetch_recent_daily_candles(instrument)
      next unless candles.present? && candles.size > 10

      avg_volume = calculate_average_volume(candles)
      next if avg_volume < AVG_VOLUME_MIN

      instrument.update(tradable: true) if tradable?(candles)
    end
  end

  private

  def fetch_recent_daily_candles(instrument)
    # Fetch daily candles for the last 30 days
    DhanHQ::Models::HistoricalData.daily(
      security_id: instrument.security_id,
      exchange_segment: instrument.exchange_segment,
      instrument: Instrument.instruments[instrument.instrument],
      expiry_code: 0,
      oi: true,
      from_date: (Time.zone.today - 30).to_s,
      to_date: (Time.zone.today - 1).to_s
    )
  rescue StandardError => e
    Rails.logger.error("Data fetch error for #{instrument.symbol_name}: #{e.message}")
    nil
  end

  def calculate_average_volume(candles)
    volumes = candles.pluck(:volume)
    volumes.sum / volumes.size
  end

  def tradable?(candles)
    closes = candles.pluck(:close)
    highs = candles.pluck(:high)
    lows = candles.pluck(:low)

    atr = TechnicalAnalysis::Atr.calculate(highs, lows, closes)&.last
    adx = TechnicalAnalysis::Adx.calculate(highs, lows, closes)&.last
    recent_close = closes.last

    return false unless atr && adx && recent_close

    volatility_good = (atr / recent_close) >= ATR_PERCENT_MIN
    strong_trend = adx >= ADX_MIN

    volatility_good && strong_trend
  end
end
