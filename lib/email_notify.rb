class EmailNotify
  def self.send_comment(comment, user)
    return if user.email.blank?

    begin
      NotificationMailer.create_comment(comment, user).deliver_now
    rescue => err
      Rails.logger.error "Unable to send comment email: #{err.inspect}"
    end
  end

  def self.send_article(article, user)
    return if user.email.blank?

    begin
      NotificationMailer.create_article(article, user).deliver_now
    rescue => err
      Rails.logger.error "Unable to send article email: #{err.inspect}"
    end
  end
end
