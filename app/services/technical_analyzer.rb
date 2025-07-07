require 'technical-analysis'

class TechnicalAnalyzer
  INDICATORS = %i[
    macd rsi ema_cross bollinger adx atr obv stochastic
  ].freeze

  def initialize(candles, style)
    @candles = candles
    @style = style
    @closes = candles.pluck(:close)
    @highs = candles.pluck(:high)
    @lows = candles.pluck(:low)
    @volumes = candles.pluck(:volume)
  end

  def analyze
    INDICATORS.filter_map do |indicator|
      send("#{indicator}_signal")
    end
  end

  def macd_signal
    macd = TechnicalAnalysis::Macd.calculate(@closes)
    hist = macd[:histogram]&.last
    return unless hist

    {
      indicator: 'MACD',
      signal: hist.positive? ? 'Bullish' : 'Bearish',
      value: hist.round(2)
    }
  end

  def rsi_signal
    rsi = TechnicalAnalysis::Rsi.calculate(@closes, period: 14).last
    return unless rsi

    signal =
      if rsi > 70
        'Overbought'
      elsif rsi < 30
        'Oversold'
      end
    signal ? { indicator: 'RSI', signal:, value: rsi.round(2) } : nil
  end

  def ema_cross_signal
    fast_period = @style == :intraday ? 9 : 20
    slow_period = @style == :intraday ? 21 : 50
    ema_fast = TechnicalAnalysis::Ema.calculate(@closes, period: fast_period).last
    ema_slow = TechnicalAnalysis::Ema.calculate(@closes, period: slow_period).last
    return unless ema_fast && ema_slow

    {
      indicator: 'EMA Cross',
      signal: ema_fast > ema_slow ? 'Bullish Cross' : 'Bearish Cross',
      value: (ema_fast - ema_slow).round(2)
    }
  end

  def bollinger_signal
    bb = TechnicalAnalysis::BollingerBands.calculate(@closes)
    upper = bb[:upper_band]&.last
    lower = bb[:lower_band]&.last
    price = @closes.last
    return unless upper && lower

    if price > upper
      { indicator: 'Bollinger Bands', signal: 'Above Upper Band', value: price.round(2) }
    elsif price < lower
      { indicator: 'Bollinger Bands', signal: 'Below Lower Band', value: price.round(2) }
    end
  end

  def adx_signal
    adx = TechnicalAnalysis::Adx.calculate(@highs, @lows, @closes)&.last
    return unless adx

    {
      indicator: 'ADX',
      signal: adx > 25 ? 'Strong Trend' : 'Weak Trend',
      value: adx.round(2)
    }
  end

  def atr_signal
    atr = TechnicalAnalysis::Atr.calculate(@highs, @lows, @closes)&.last
    return unless atr

    {
      indicator: 'ATR',
      signal: 'Volatility Level',
      value: atr.round(2)
    }
  end

  def obv_signal
    obv = TechnicalAnalysis::Obv.calculate(@closes, @volumes)&.last
    return unless obv

    {
      indicator: 'OBV',
      signal: 'Volume Trend',
      value: obv.round(2)
    }
  end

  def stochastic_signal
    stoch = TechnicalAnalysis::Stochastic.calculate(@highs, @lows, @closes)&.last
    return unless stoch

    signal =
      if stoch > 80
        'Overbought'
      elsif stoch < 20
        'Oversold'
      end
    signal ? { indicator: 'Stochastic', signal:, value: stoch.round(2) } : nil
  end
end
