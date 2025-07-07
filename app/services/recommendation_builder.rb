class RecommendationBuilder
  RISK_PERCENT = { intraday: 0.5, swing: 1, long: 2, options_intraday: 1 }.freeze

  def initialize(instrument, signals, style, candles)
    @instrument = instrument
    @signals = signals
    @style = style.to_sym
    @candles = candles
    @current_price = candles.last[:close]
  end

  def build
    atr = TechnicalAnalysis::Atr.calculate(
      @candles.pluck(:high),
      @candles.pluck(:low),
      @candles.pluck(:close)
    ).last

    sl = (@current_price - (atr * 1.5)).round(2)
    tp = (@current_price + (atr * 3)).round(2)
    qty = suggested_quantity(@current_price, sl)

    {
      instrument: @instrument,
      style: @style,
      signals: @signals,
      composite_score: SignalScorer.new(@signals).composite_score,
      entry_price: @current_price,
      stop_loss: sl,
      take_profit: tp,
      quantity: qty,
      pyramid_entries: pyramid_points(@current_price, atr),
      option_strike: @style == :options_intraday ? OptionSelector.optimal_strike(@instrument.symbol, @current_price, determine_trend) : nil,
      expected_profit_percent: @style == :options_intraday ? 40.0 : 15.0,
      explanation: AiExplainer.generate(@instrument.symbol, @signals, SignalScorer.new(@signals).composite_score, @style)
    }
  end

  private

  def suggested_quantity(entry, sl, capital = 100_000)
    risk_amount = capital * (RISK_PERCENT[@style] / 100.0)
    qty = (risk_amount / (entry - sl).abs).floor
    qty.positive? ? qty : 1
  end

  def pyramid_points(price, atr)
    {
      add_more_at: [
        (price + atr).round(2),
        (price + (2 * atr)).round(2)
      ]
    }
  end

  def determine_trend
    bullish = @signals.any? { |s| s[:signal].to_s.downcase.include?('bullish') }
    bullish ? :bullish : :bearish
  end
end
