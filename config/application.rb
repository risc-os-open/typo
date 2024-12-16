require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module Typo
  class Application < Rails::Application

    # Initialize configuration defaults for originally generated Rails version.
    #
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    #
    config.autoload_lib(ignore: %w[assets tasks])

    # Permitted hosts.
    #
    config.hosts << "epsilon.arachsys.com"

    # Legacy data run through YAML deserialisation includes classes (stated in
    # the data itself) such as HashWithIndifferentAccess, usually prohibited.
    #
    config.active_record.yaml_column_permitted_classes = [
      Array,
      Hash,
      'HashWithIndifferentAccess',              # A string, else true name "ActiveSupport::HashWithIndifferentAccess" is used and fails on *legacy* data...
      ActiveSupport::HashWithIndifferentAccess, # ...but any saved, modern data will use this instead, so we need to permit that too.
    ]
  end
end
