class Website < ActiveRecord::Base
  STATUSES = { failing: 'failing', success: 'success', pending: 'pending' }
  CHECKS_QUEUE = "website_checks"

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
  after_create   -> { schedule! }

  #####
  # Remove running and scheduled jobs
  #####
  before_destroy -> { deactivate! }

  def status
    if failing?
      STATUSES[:failing]
    else
      if checks.any?
        checks.first.success?? STATUSES[:success] : STATUSES[:pending]
      else
        STATUSES[:pending]
      end
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

  def schedule!
    WebsiteCheck.perform_in check_interval.seconds, id
  end

  def recover!
    update_attribute :recent_failures_count, 0
  end

  def scheduled?
    schedule = Sidekiq::ScheduledSet.new

    schedule.find { |job| job.args.include?(id) and job.queue == CHECKS_QUEUE }.present?
  end

  def running?
    queue = Sidekiq::Queue.new(CHECKS_QUEUE)

    queue.find { |job| job.args.include?(id) and job.queue == CHECKS_QUEUE }.present?
  end

  def activate!
    update_attribute :active, true

    schedule! unless scheduled? or running?
  end

  def deactivate!
    update_attribute :active, false

    Sidekiq.redis do |redis|
      queue_key = "queue:#{CHECKS_QUEUE}"
      jobs = redis.lrange(queue_key, 0, -1)

      jobs.each do |job|
        redis.lrem(queue_key, 0, job) if JSON.load(job)['args'].include?(id)
      end
    end

    schedule = Sidekiq::ScheduledSet.new
    jobs = schedule.select { |job| job.args.include?(id) }

    jobs.each(&:delete)
  end
end
