# frozen_string_literal: true

namespace :instruments do
  desc 'Download master CSV and populate instruments + derivatives'
  task import: :environment do
    InstrumentsImporter.import
  end
end
