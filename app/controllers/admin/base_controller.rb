class Admin::BaseController < ApplicationController
  layout 'administration'
  before_action :login_required

  include_protected ActionView::Helpers::TagHelper, ActionView::Helpers::TextHelper
end
