class NotificationMailer < ApplicationMailer
  default from: "monitoring@kama.com"

  def failure(website)
    @website = website
    @subject = default_i18n_subject(url: @website.url, checks: @website.recent_failures_count)

    mail(
      to: Recipient.pluck(:email),
      subject: @subject
    )
  end

  def repetitive_failure(website)
    @website = website
    @subject = default_i18n_subject(url: @website.url, checks: @website.recent_failures_count)

    mail(
      to: Recipient.pluck(:email),
      subject: @subject
    )
  end

  def recovery(website)
    @website = website
    @subject = default_i18n_subject(url: @website.url, checks: @website.recent_failures_count)

    mail(
      to: Recipient.pluck(:email),
      subject: @subject
    )
  end
end
