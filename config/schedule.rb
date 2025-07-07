# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

set :output, 'log/cron.log'
set :environment, 'development' # change to 'production' in prod

every 5.minutes do
  runner "RecommendationJob.perform_now('intraday')"
end

every 15.minutes do
  runner "RecommendationJob.perform_now('options_intraday')"
end

every :weekday, at: '4:00 pm' do
  runner "RecommendationJob.perform_now('swing')"
end

every :monday, at: '9:30 am' do
  runner "RecommendationJob.perform_now('long')"
end

every :sunday, at: '6:00 pm' do
  runner 'TradingUniverseJob.perform_now'
end