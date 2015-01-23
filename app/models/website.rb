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
  after_create :schedule!

  #####
  # Remove running and scheduled jobs
  #####
  before_destroy :deactivate!

  # Overwrites default #check_interval
  def check_interval
    failing?? Configurable.critical_check_interval : read_attribute(:check_interval)
  end

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

  def requires_failure_notification?
    _critical_failures_count = Configurable.critical_failures_count

    if recent_failures_count > _critical_failures_count
      # tell if a number is in arithmetic seq
      ( (recent_failures_count - _critical_failures_count) % Configurable.repeat_notification_failures_count ).zero?
    else
      recent_failures_count == _critical_failures_count
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
    # CsvImportJob.set(wait_until: Date.tomorrow.noon).perform_later('/tmp/my_file.csv')
    WebsiteCheck.set(wait: check_interval.seconds).perform_later(id) # perform_in check_interval.seconds, id
  end

  def recover!
    update_attribute :recent_failures_count, 0

    recovery_notification!
  end

  def failing!
    increment! :recent_failures_count

    failure_notification! if requires_failure_notification?
  end

  def scheduled?
    schedule = Sidekiq::ScheduledSet.new

    schedule.find { |job| job.args.first['arguments'].include?(id) and job.queue == CHECKS_QUEUE }.present?
  end

  def running?
    queue = Sidekiq::Queue.new(CHECKS_QUEUE)

    queue.find { |job| job.args.first.arguments.include?(id) }.present?
  end

  def activate!
    update_attribute :active, true

    schedule! unless scheduled? or running?
  end

  def deactivate!
    update_attribute :active, false

    stop_running_jobs!
    remove_scheduled_jobs!
  end

  private

  def failure_notification!
    if recent_failures_count > Configurable.critical_failures_count
      NotificationMailer.repetitive_failure(self).deliver_later
    else
      NotificationMailer.failure(self).deliver_later
    end
  end

  def recovery_notification!
    NotificationMailer.recovery(self).deliver_later
  end

  def stop_running_jobs!
    Sidekiq.redis do |redis|
      queue_key = "queue:#{CHECKS_QUEUE}"
      jobs = redis.lrange(queue_key, 0, -1)

      jobs.each do |job|
        redis.lrem(queue_key, 0, job) if JSON.load(job)['args'].first['arguments'].include?(id)
      end
    end
  end

  def remove_scheduled_jobs!
    schedule = Sidekiq::ScheduledSet.new
    jobs = schedule.select { |job| job.args.first['arguments'].include?(id) }

    jobs.each(&:delete)
  end
end
