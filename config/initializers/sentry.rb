Raven.configure do |config|
  config.dsn = 'https://fdc39fd59f714c518f461552755c1559:55abdd5ecf2145edba1e01080c6773ba@sentry.io/180026'
  config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)
  config.environments = %w(production)
end
