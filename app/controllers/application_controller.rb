class ApplicationController < ActionController::Base

  # Hub single sign-on support.

  require 'hub_sso_lib'
  include HubSsoLib::Core
  before_action :hubssolib_beforehand
  after_action :hubssolib_afterwards

  # Standard Typo gubbins follows, including its own admin login system.

  include LoginSystem
  before_action :fire_triggers

  # Extra filter to prime URL writing so that it doesn't make invalid
  # assumptions about protocol or port

  before_action :prime_url_writer

  protected

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

  @@blog_id_for = Hash.new

  # The Blog object for the blog that matches the current request.  This is looked
  # up using Blog.find_blog and cached for the lifetime of the controller instance;
  # generally one request.
  def this_blog
    @blog ||= if @@blog_id_for[blog_base_url]
                Blog.find(@@blog_id_for[blog_base_url])
              else
                blog = Blog.find_blog(blog_base_url)
                @@blog_id_for[blog_base_url] = blog.id
                blog
              end
  end
  helper_method :this_blog

  # The base URL for this request, calculated by looking up the URL for the main
  # blog index page.  This is matched with Blog#base_url to determine which Blog
  # is supposed to handle this URL
  def blog_base_url
    url_for(:controller => '/articles').gsub(%r{/$},'')
  end

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
end

