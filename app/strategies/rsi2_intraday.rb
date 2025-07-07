module Strategies
  class Rsi2Intraday < Base
    STYLE = :intraday
    NAME  = 'rsi-2'.freeze

    def call
      out = []
      Instrument.where(segment: 'E').find_each(batch_size: 500) do |inst|
        closes = ohlc(inst)
        next if closes.size < 30

        rsi = Talib.rsi(closes, 2).last
        next unless rsi && rsi < 10

        out << Result.new(
          instrument: inst,
          action: :buy,
          price: closes.last,
          confidence: (10 - rsi).round(2),
          meta: { rsi: rsi.round(2) }
        )
      end
      out
    end
  end
end
