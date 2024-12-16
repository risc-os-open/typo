module MailHelper
  # Mutter... ActionMailer doesn't do fragment caching.

  # TODO: Overwrites ApplicationHelper#html since Rails now loads all helpers.
  #
  # def html(content, what=:all)
  #   content.html(what)
  # end
end

