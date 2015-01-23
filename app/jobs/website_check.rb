class WebsiteCheck
  include Sidekiq::Worker

  sidekiq_options :queue => :website_checks

  def perform(website_id)
    @website = Website.find(website_id)

    response_code = begin
                      Timeout.timeout(Configurable.request_timeout) do
                        http = Net::HTTP.new(@website.uri.host, @website.uri.port).tap { |_http| _http.use_ssl = true if @website.https? }

                        http.head(@website.uri.path).code.to_i
                      end
                    rescue SocketError
                      0   # Invalid url?
                    rescue Timeout::Error
                      408 # Request timeout
                    end

    # sanity check, make sure @website record hasn't been destroyed by user
    return nil unless @website.reload.present?

    website_check = @website.checks.create(response_code: response_code)

    if website_check.failure?
      @website.failing!
    else
      @website.recover! if @website.failing?
    end

    #if @website.requires_failure_notification?
      #@website.send_failure_notification!
    #end

    #if check_failed?(response_code)
      #@website.increment! :recent_failures_count
    #else
      #@website.recover! if @website.failing?
    #end

    #@website.checks.create(response_code: response_code)

    # Re-schedule the job
    check_interval = (@website.failing?? Configurable.critical_check_interval : @website.check_interval).seconds

    if @website.active?
      WebsiteCheck.perform_in check_interval, @website.id
    end
  end

end
