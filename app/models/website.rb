class Website < ActiveRecord::Base
  validates :check_interval, :url, presence: true
  # only validate url format if url is present (avoid unnecesarry validation errors)
  validates :url, url: true, uniqueness: true, if: -> { url.present? }
  # check_interval must be greater than "critical_check_interval" value!
  # uses lambda to avoid "production" mode class caching missbehivour
  validates :check_interval, numericality: { greater_than: -> (website) { Configurable.critical_check_interval } }, if: -> { check_interval.present? }

  default_scope -> { order(:created_at => :desc) }
end
