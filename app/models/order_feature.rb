# frozen_string_literal: true

class OrderFeature < ApplicationRecord
  # Associations
  belongs_to :featureable, polymorphic: true

  # Validations
  validates :bracket_flag, :cover_flag, inclusion: { in: %w[Y N] }, allow_nil: true
end
