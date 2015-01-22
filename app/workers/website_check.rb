class WebsiteCheck
  include Sidekiq::Worker

  # sidekiq_options :queue => :website_checks

  def perform(website_id)
    @website = Website.find(website_id)

    logger.info "running request: #{@website.uri.host}"
    response_code = Timeout.timeout(Configurable.request_timeout) do
      begin
        http = Net::HTTP.new(@website.uri.host, @website.uri.port).tap { |_http| _http.use_ssl = true if @website.https? }

        http.head(@website.uri.path).code.to_i
      rescue SocketError
        0   # Invalid url?
      rescue Timeout::Error
        408 # Request timeout
      end
    end

    logger.info "ran request: #{@website.uri.host}"
    # sanity check, make sure @website record hasn't been destroyed by user
    return nil unless @website.reload.present?

    if check_failed?(response_code)
      @website.increment! :recent_failures_count
    else
      @website.recover! if @website.failing?
    end

    @website.checks.create(response_code: response_code)
    logger.info "Persisted check results"

    # Re-schedule the job
    check_interval = (@website.failing?? Configurable.critical_check_interval : @website.check_interval).seconds

    if @website.active?
      WebsiteCheck.perform_in check_interval, @website.id

      logger.info "Re-scheduled check: running in: #{check_interval} seconds.."
    end
  end

  private

  def check_failed? response_code
    response_code.to_s[0] != "2"
  end

  def check_successed? response_code
    not check_failed?(response_code)
  end
end
