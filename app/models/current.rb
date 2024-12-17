# Thread-safe access to per-request concepts such as the request object. This
# arises from all sorts of hackery around needing URLs in models, which is in
# the context of Typo a very reasonable thing to want.
#
# Initialised by ApplicationController#set_current!.
#
class Current < ActiveSupport::CurrentAttributes
  attribute :blog
  attribute :request
end
