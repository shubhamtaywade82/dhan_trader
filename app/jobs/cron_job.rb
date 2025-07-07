class CronJob < ApplicationJob
  class_attribute :cron_expression
  def self.schedule
    set(cron: cron_expression).perform_later unless scheduled?
  end

  def self.scheduled?
    Delayed::Job.where('handler LIKE ?', "%job_class: #{name}%")
                .where(failed_at: nil).exists?
  end
end