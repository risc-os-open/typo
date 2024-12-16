# Thread-safe access to per-request concepts such as the request object. This
# is needed for some of Typo's more curious features, such as permalink URLs
# generated from within instances of the Blog model - that instance needs to
# know the request host, protocol etc. and we really don't want to have that
# being some weird thing you must remember to configure specially just for
# this Rails application.
#
# Initialised by ApplicationController#set_current!.
#
class Current < ActiveSupport::CurrentAttributes
  attribute :request
end
