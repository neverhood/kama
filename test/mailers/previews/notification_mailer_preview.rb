# Preview all emails at http://localhost:3000/rails/mailers/notification_mailer
class NotificationMailerPreview < ActionMailer::Preview
  def recovery
    NotificationMailer.recovery(Website.first).deliver_now
  end

  def failure
    NotificationMailer.failure(Website.first).deliver_now
  end

  def repetitive_failure
    NotificationMailer.repetitive_failure(Website.first).deliver_now
  end
end
