# 2024-12-11 (ADH)
#
# Typo for Rails 1 had a custom localisation system based around plain old Ruby
# objects and a method simply called '_' (underscore). Messages were written in
# English as a default inside such method calls, but there was a localisation
# file for French too (which was just a big Ruby script setting up messages).
#
# I18n is standardised in Rails now and looks nothing like the original. Rather
# than go to the trouble of trying to half-merge any later Typo or Publify
# versions or otherwise adapt the very large number of "_(...)" calls, the ROOL
# minimal Rails 7+ conversion just stubs the method to return the string.
#
module LocalizationHelper
  def _(str)
    str
  end
end
