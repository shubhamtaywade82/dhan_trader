class SignalScorer
  WEIGHTS = {
    macd: 20,
    rsi: 15,
    ema_cross: 20,
    bollinger: 10,
    adx: 10,
    atr: 5,
    obv: 5,
    stochastic: 5
  }.freeze

  def initialize(signals)
    @signals = signals
  end

  def composite_score
    score = @signals.sum do |s|
      WEIGHTS[s[:indicator].downcase.tr(' ', '_').to_sym] || 0
    end
    score >= 70 ? score : nil
  end
end
