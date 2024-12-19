class ApplicationController < ActionController::Base
  include Pagy::Backend

  before_action :set_current!

  # Hub single sign-on support. Run the Hub filters for all actions to ensure
  # activity timeouts etc. work properly.
  #
  require 'hub_sso_lib'
  include HubSsoLib::Core

  before_action :hubssolib_beforehand
  after_action :hubssolib_afterwards

  # Rescue all exceptions (bad form) to rotate the Hub key (good) and render or
  # raise the exception again (rapid reload for default handling).
  #
  rescue_from ::Exception, with: :on_error_rotate_and_raise

  # Standard Typo gubbins follows, including its own admin login system.

  include LoginSystem
  before_action :fire_triggers

  # Extra filter to prime URL writing so that it doesn't make invalid
  # assumptions about protocol or port

  before_action :prime_url_writer

  def self.include_protected(*modules)
    modules.reverse.each do |mod|
      included_methods = mod.public_instance_methods.reject do |meth|
        self.method_defined?(meth)
      end
      self.send(:include, mod)
      included_methods.each do |meth|
        protected meth
      end
    end
  end

  protected

    # Run pagy() on a given ActiveRecord scope/collection, with a default
    # limit of 20 items per page overridden by the 'default_limit' parameter,
    # or by query parameter 'items', the latter taking precedence but being
    # capped to a list size of 200 to keep server resource usage down.
    #
    # https://github.com/ddnexus/pagy
    #
    def pagy_with_params(scope:, default_limit: 20)
      limit        = params[:items]&.to_i || default_limit
      limit        = limit.clamp(1, 200)
      pagy_options = { :limit => limit }

      # Some Typo views do e.g. "?page=&..." - i.e. the param is there, but it
      # has no value. This makes Pagy grumpy, as a #to_i turns "nil" into "0"
      # and it complains that page zero is invalid.
      #
      params.delete(:page) if params.key?(:page) && params[:page].blank?

      pagy(scope, **pagy_options)
    end

    def prime_url_writer
      $url_writer_request_information = request;
    end

    def fire_triggers
      Trigger.fire
    end

    # Axe?
    def server_url
      this_blog.base_url
    end

    def cache
      $cache ||= SimpleCache.new 1.hour
    end

    # The Blog object for the blog that matches the current request. This is
    # looked up using Blog.find_blog and cached for the lifetime of the
    # controller instance; generally one request. While ActiveRecord would
    # cache this for us, it saves a bit of time to not bother even calling it
    # and leads to far less log noise.
    #
    def this_blog
      @blog ||= Blog.find_blog(blog_base_url)
    end
    helper_method :this_blog

    # The base URL for this request, calculated by looking up the URL for the main
    # blog index page.  This is matched with Blog#base_url to determine which Blog
    # is supposed to handle this URL
    #
    def blog_base_url
      url_for(:controller => 'articles').gsub(%r{/$},'')
    end

  private

    # Record useful information in the thread-safe Current singleton, that can
    # then be accessed by any part of the stack during a request.
    #
    def set_current!
      Current.blog    = self.this_blog()
      Current.request = self.request()
    end

    # Renders an exception, retaining Hub login. Regenerate any exception
    # within five seconds of a previous render to 'raise' to default Rails
    # error handling, which (in non-Production modes) gives additional
    # debugging context and an inline console, but loses the Hub session
    # rotated key, so you're logged out.
    #
    def on_error_rotate_and_raise(exception)
      hubssolib_get_session_proxy()
      hubssolib_afterwards()

      if session[:last_exception_at].present?
        last_at = Time.parse(session[:last_exception_at]) rescue nil
        raise if last_at.present? && Time.now - last_at < 5.seconds
      end

      session[:last_exception_at] = Time.now.iso8601(1)
      render 'exception', locals: { exception: exception }
    end

end
