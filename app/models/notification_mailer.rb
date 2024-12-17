class NotificationMailer < ActionMailer::Base
  layout 'minimal'
  helper 'mail'

  def create_article(article, user)
    self.setup_ivars(user, article)

    @article        = article
    @subject        = "[#{@blog_name}] New article: #{article.title}"
    @body[:article] = article

    self.send_mail()
  end

  def create_comment(comment, user)
    self.setup_ivars(user, comment)

    @comment        = comment
    @article        = comment.article
    @subject        = "[#{@blog_name}] New comment on #{comment.article.title}"
    @body[:article] = comment.article
    @body[:comment] = comment

    self.send_mail()
  end

  private

    def setup_ivars(user, content)
      @blog        = content.blog
      @body        = {}
      @body[:user] = user
      @body[:blog] = @blog
      @blog_name   = @blog.blog_name
      @recipients  = user.email
      @from        = content.blog.email_from
      @headers     = {'X-Mailer' => "Typo #{TYPO_VERSION}"}
    end

    def send_mail
      mail(
        to:      @recipients,
        from:    @from,
        subject: @subject
      )
    end

end
