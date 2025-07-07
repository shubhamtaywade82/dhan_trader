module Recommendation
  class Runner
    STRATEGIES = [
      Strategies::Rsi2Intraday.new
      # Strategies::BreakoutSwing.new,
      # ...
    ]

    def self.execute!
      STRATEGIES.each do |s|
        s.call.each { |sig| persist(s, sig) }
      end
    end

    def self.persist(strategy, sig)
      Recommendation.create!(
        instrument: sig.instrument,
        strategy: strategy.class::NAME,
        style: strategy.class::STYLE,
        action: sig.action,
        trigger_price: sig.price,
        confidence: sig.confidence,
        valid_till: Time.zone.today.change(hour: 15, min: 30),
        meta: sig.meta
      )
    end
  end
end
