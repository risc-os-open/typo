# Be sure to restart your webserver when you modify this file.

# Rails Gem Version
RAILS_GEM_VERSION = '1.2.6' unless defined? RAILS_GEM_VERSION

# Uncomment below to force Rails into production mode
# (Use only when you can't set environment variables through your web/app server)
# ENV['RAILS_ENV'] = 'production'

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

# Location of application relative to document root in terms of
# URLs (i.e. according to the web server configuration, not the
# filesystem location).

PATH_PREFIX = '/news' # Needed by dodgy code in "vendor/plugins/typo_textfilter_lightbox/lib/typo_textfilter_lightbox.rb"

Rails::Initializer.run do |config|
  # Skip frameworks you're not going to use
  # config.frameworks -= [ :action_web_service, :action_mailer ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/app/services )

  # I need the localization plugin to load first
  # Otherwise, I can't localize plugins <= localization
  config.plugins = [ 'localization' ]
  Dir.entries("#{RAILS_ROOT}/vendor/plugins/").each { |dir|  
    config.plugins.push("#{dir}") if File.directory?("#{RAILS_ROOT}/vendor/plugins/#{dir}/lib")  
  }
  
  config.load_paths += %W(
    vendor/rubypants
    vendor/akismet
    vendor/redcloth/lib
    vendor/bluecloth/lib
    vendor/flickr
    vendor/syntax/lib
    vendor/sparklines/lib
    vendor/uuidtools/lib
    vendor/jabber4r/lib
    vendor/mocha/lib
    vendor/memcache-client/lib
    vendor/cached_model/lib
  ).map {|dir| "#{RAILS_ROOT}/#{dir}"}.select { |dir| File.directory?(dir) }

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  config.log_level = :warn

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake create_sessions_table')
  config.action_controller.session_store = :active_record_store

  # Enable page/fragment caching by setting a file-based store
  # (remember to create the caching directory and make it readable to the application)
  config.action_controller.fragment_cache_store = :file_store, "#{RAILS_ROOT}/tmp/cache"

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector
  config.active_record.observers = :email_notifier, :web_notifier

  config.active_record.allow_concurrency = false

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc

  # Use Active Record's schema dumper instead of SQL when creating the test database
  # (enables use of different database adapters for development and test environments)
  # config.active_record.schema_format = :ruby

  # See Rails::Configuration for more options
end

# Add new inflection rules using the following format
# (all these examples are active by default):
# Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

Inflector.inflections {|i| i.uncountable %w(feedback)}

# Include your application configuration below

# Allow multiple Rails applications by giving the session cookie a
# unique prefix.

ActionController::CgiRequest::DEFAULT_SESSION_OPTIONS[:session_key] = 'typoapp_session_id'

# Load included libraries.
require 'redcloth'
require 'bluecloth'
require 'rubypants'
require 'flickr'
require 'uuidtools'

require 'migrator'
require 'rails_patch/active_record'
require 'login_system'
require 'typo_version'
require 'metafragment'
require 'actionparamcache'
$KCODE = 'u'
require 'jcode'
require 'xmlrpc_fix'
require 'transforms'
require 'builder'

require 'typo_deprecated'

#MemoryProfiler.start(:delay => 10, :string_debug => false)

unless Builder::XmlMarkup.methods.include? '_attr_value'
  # Builder 2.0 has many important fixes, but for now we will only backport
  # this one...
  class Builder::XmlMarkup
    # Insert the attributes (given in the hash).
    def _insert_attributes(attrs, order=[])
      return if attrs.nil?
      order.each do |k|
        v = attrs[k]
        @target << %{ #{k}="#{_attr_value(v)}"} if v # " WART
      end
      attrs.each do |k, v|
        @target << %{ #{k}="#{_attr_value(v)}"} unless order.member?(k) # " WART
      end
    end

   def _attr_value(value)
      case value
      when Symbol
        value.to_s
      else
        _escape(value.to_s).gsub(%r{"}, '&quot;')  # " WART
      end
    end
  end
end

ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS.merge!(
  :long_weekday => '%a %B %e, %Y %H:%M'
)

ActionMailer::Base.default_charset = 'utf-8'

if RAILS_ENV != 'test'
  begin
    mail_settings = YAML.load(File.read("#{RAILS_ROOT}/config/mail.yml"))

    ActionMailer::Base.delivery_method = mail_settings['method']
    ActionMailer::Base.server_settings = mail_settings['settings']
  rescue
    # Fall back to using sendmail by default
    ActionMailer::Base.delivery_method = :sendmail
  end
end

FLICKR_KEY='84f652422f05b96b29b9a960e0081c50'

#require 'memcache_util'
require 'cached_model'
CachedModel.use_local_cache = true
CachedModel.use_memcache = false

# Uncomment this to choose your blog's language
#Localization.lang = 'fr_FR'
