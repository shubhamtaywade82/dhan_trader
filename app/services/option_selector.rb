class OptionSelector
  def self.optimal_strike(_symbol, spot_price, trend)
    step = 50
    base = (spot_price / step).round * step
    strike = trend == :bullish ? base + step : base - step
    "#{strike} #{trend == :bullish ? 'CE' : 'PE'}"
  end
end
