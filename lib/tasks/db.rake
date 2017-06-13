namespace :db do
  task sync_from_gmail: :environment do |_, args|
    if Rails.env.production?
      database_path = fetch_database_from_gmail
      replace_database(database_path)
    end
  end

  def fetch_database_from_gmail
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

  def replace_database(path)
    conf = Rails.configuration.database_configuration[Rails.env]
    `gzip -dc #{path} | mysql -h#{conf['host']} -u#{conf['username']} -p#{conf['password']} #{conf['database']}`
    File.delete path
  end
end
