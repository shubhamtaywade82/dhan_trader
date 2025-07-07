class RecommendationJob < CronJob
  self.cron_expression = '*/5 9-15 * * 1-5' # every 5 min Mon-Fri during market hrs
  queue_as :default
  def perform(style: :intraday)
    Recommendation::Runner.execute!(style)
  end
end
