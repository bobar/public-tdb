class KeenEvent
  def self.publish(collection, properties)
    return unless Rails.env.production?
    Keen.publish(collection, properties)
  rescue => e
    Rails.logger.warn "Failed to publish Keen event: #{e.message} #{e.backtrace.join("\n")}"
  end
end
