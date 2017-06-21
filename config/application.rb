require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

BOB = 'bobar'.freeze

module PublicTdb
  class Application < Rails::Application
    config.time_zone = 'Europe/Paris'
    config.active_record.raise_in_transactional_callbacks = true
    config.active_record.default_timezone = :utc
    config.autoload_paths += ["#{config.root}/lib"]
    config.log_level = ENV['LOG_LEVEL'].downcase.to_sym if ENV['LOG_LEVEL']
    config.i18n.default_locale = :fr
    config.filter_parameters << :password

    ActiveRecord::Base.schema_migrations_table_name = 'schema_migrations_public'
  end
end
