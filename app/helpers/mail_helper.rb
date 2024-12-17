module MailHelper
  def html_for_email(content, what=:all)
    content.html(what)
  end
end

