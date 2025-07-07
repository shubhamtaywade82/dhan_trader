module Strategies
  Result = Struct.new(:instrument, :action, :price, :confidence, :meta, keyword_init: true)

  class Base
    def ohlc(instrument, interval: '15')
      DhanHQ::Models::HistoricalData.intraday(
        security_id: instrument.security_id,
        exchange_segment: instrument.exchange_segment,
        instrument: instrument.instrument_type,
        interval: interval,
        from_date: (Time.zone.today - 2).to_s,
        to_date: Time.zone.today.to_s
      )['data'].map { _1['CLOSE'].to_f }
    rescue StandardError
      []
    end
  end
end
