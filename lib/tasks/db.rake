namespace :db do
  task sync_from_gmail: :environment do |_, args|
    if Rails.env.production?
      database_path = SyncDb.fetch_database_from_gmail
      SyncDb.replace_database(database_path)
    end
  end
end
