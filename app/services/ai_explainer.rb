class AiExplainer
  def self.generate(symbol, signals, composite_score, style)
    prompt = <<~PROMPT
      You are an institutional trading analyst. Evaluate #{symbol} for #{style} trading.
      Indicators:
      #{signals.map { |s| "#{s[:indicator]}: #{s[:signal]} (#{s[:value]})" }.join("\n")}
      Composite Technical Score: #{composite_score}/100.

      Provide a trading recommendation (Buy/Sell/Hold), suggested entry price, stop-loss, take-profit, and rationale.
    PROMPT

    OpenAI::Client.new.chat(
      parameters: {
        model: 'gpt-4o',
        messages: [{ role: 'user', content: prompt }],
        temperature: 0.2
      }
    ).dig('choices', 0, 'message', 'content')
  rescue StandardError => e
    "Analysis unavailable (#{e.message})"
  end
end
