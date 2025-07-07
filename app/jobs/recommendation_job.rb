class RecommendationJob < ApplicationJob
  queue_as :default

  TIMEFRAMES = { intraday: '5', swing: '1D', long: '1W', options_intraday: '3' }.freeze

  def perform(style)
    instruments = select_instruments(style)

    instruments.each do |instrument|
      candles = fetch_candles(instrument.security_id, TIMEFRAMES[style.to_sym])
      next unless candles.present? && candles.size > 50

      analyzer = TechnicalAnalyzer.new(candles, style)
      signals = analyzer.analyze
      next if signals.empty?

      recommendation = RecommendationBuilder.new(instrument, signals, style, candles).build
      Recommendation.create!(recommendation.merge(generated_at: Time.current))
    end
  end

  private

  def select_instruments(style)
    style.to_sym == :options_intraday ? Instrument.where(symbol: %w[NIFTY BANKNIFTY]) : Instrument.where(tradable: true)
  end

  def fetch_candles(security_id, interval)
    Rails.cache.fetch("candles:#{security_id}:#{interval}", expires_in: 10.minutes) do
      DhanHQ::Models::HistoricalData.intraday(security_id: security_id, interval: interval)
    end
  rescue StandardError => e
    Rails.logger.error("Candle fetch error: #{e.message}")
    []
  end
end
