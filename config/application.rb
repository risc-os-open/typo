require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Typo
  class Application < Rails::Application

    # Initialize configuration defaults for originally generated Rails version.
    #
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    #
    config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.

    config.time_zone = 'UTC'
    config.active_record.default_timezone = :utc

    # Add the ROOL theme for the fixed header/footer fixed components.
    #
    config.paths['app/views'].unshift(Rails.root.join('app', 'views', 'themes', 'risc_os_open', 'views'))

    # Legacy data run through YAML deserialisation includes classes (stated in
    # the data itself) such as HashWithIndifferentAccess, usually prohibited.
    #
    config.active_record.yaml_column_permitted_classes = [
      Array,
      Hash,
      'HashWithIndifferentAccess',              # A string, else true name "ActiveSupport::HashWithIndifferentAccess" is used and fails on *legacy* data...
      ActiveSupport::HashWithIndifferentAccess, # ...but any saved, modern data will use this instead, so we need to permit that too.
    ]

    # Add the shared ROOL view components.
    #
    shared_views_path = if ENV['SHARED_FILES_PATH'].blank?
      Rails.root.join('..', 'common', 'views')
    else
      Rails.root.join(ENV['SHARED_FILES_PATH'], 'views')
    end
    config.paths['app/views'].unshift(shared_views_path)

    # If running in a deployed environment, allow requests to Epsilon. Send
    # e-mail via Beta, which is on the same local network.
    #
    if Socket.gethostname == 'epsilon'
      config.hosts << "epsilon.arachsys.com"

      config.action_mailer.delivery_method = :smtp
      config.action_mailer.smtp_settings = {
        address:        'beta.arachsys.com',
        port:           25,
        domain:         'riscosopen.org',
        user_name:      nil,
        password:       nil,
        authentication: nil,
        enable_starttls_auto: true
      }
    end

  end
end
