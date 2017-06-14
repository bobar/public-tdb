class SyncDb
  def self.fetch_database_from_gmail
    path = ''
    Gmail.new('bobar.save@gmail.com', ENV['GMAIL_PASSWORD']) do |gmail|
      tdb_dump = gmail.label('[Gmail]/Corbeille').emails.last.attachments.first
      path = Rails.root.join(tdb_dump.filename)
      file = File.new(path, 'w+', encoding: 'ascii-8bit')
      file << tdb_dump.decoded
      file.close
    end
    path
  end

  def self.replace_database(path)
    return unless Rails.env.production?
    conf = Rails.configuration.database_configuration[Rails.env]
    `gzip -dc #{path}`.split(";\n").each do |line|
      ActiveRecord::Base.connection.execute(line)
    end
    Rails.logger.info 'DB synchronized'
    File.delete path
  end
end
