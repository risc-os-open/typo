source "https://rubygems.org"

ruby "3.3.0"

gem "rails", "~> 7.2.0"

# Use PostgresSQL
#
gem 'pg', '~> 1.5.8'

# Use the Puma web server [https://github.com/puma/puma]
#
gem "puma", ">= 5.0"

# Reduces boot times through caching; required in config/boot.rb
#
gem "bootsnap", require: false

# For Windows or esoteric Unix/Linux-like distributions.
#
gem 'tzinfo-data'

# Use a robust preprocessing step for JavaScript, too; this lets us manage any
# components available in NPM that have both JS and CSS components using the
# same mechanism (Yarn):
# https://rubygems.org/gems/jsbundling-rails/
#
gem 'jsbundling-rails' # ...using whatever version Rails wants

# Rails 7+ 'modern' asset pipeline:
# https://rubygems.org/gems/propshaft
#
gem 'propshaft', '~> 1.1'

# Use Hub for authentication [https://github.com/pond/hubssolib]
#
gem 'hubssolib', '~> 2.0', require: 'hub_sso_lib'

group :development, :test do

  # Standard debugger
  #
  gem 'debug'
end

group :development do

  # Use console on exceptions pages [https://github.com/rails/web-console]
  #
  gem 'web-console'
end

group :test do
end