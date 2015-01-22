class Website < ActiveRecord::Base
  STATUSES = { failing: 'failing', success: 'success', pending: 'pending' }

  validates :check_interval, :url, presence: true
  # only validate url format if url is present (avoid unnecesarry validation errors)
  validates :url, url: true, uniqueness: true, if: -> { url.present? }
  # check_interval must be greater than "critical_check_interval" value!
  # uses lambda to avoid "production" mode class caching missbehivour
  validates :check_interval, numericality: { greater_than: -> (website) { Configurable.critical_check_interval } }, if: -> { check_interval.present? }

  default_scope -> { order(:created_at => :desc) }

  has_many :checks, :dependent => :destroy

  #####
  # Creates a self-recursive background job that will launch in #check_interval seconds after record creation and will
  # re-run itself upon completion
  #####
  after_create -> { WebsiteCheck.perform_in check_interval.seconds, id }

  def status
    if failing?
      STATUSES[:failing]
    else
      checks.any?? STATUSES[:success] : STATUSES[:pending]
    end
  end

  def uri
    @_uri ||= URI.parse(url).tap { |website_url| website_url.path = "/" if website_url.path.empty? }
  end

  def https?
    uri.scheme == 'https'
  end

  def failing?
    recent_failures_count >= Configurable.critical_failures_count
  end

  def recover!
    update_attribute :recent_failures_count, 0
  end

  def activate!
    update_attribute :active, true
  end

  def deactivate!
    update_attribute :active, false
  end
end
