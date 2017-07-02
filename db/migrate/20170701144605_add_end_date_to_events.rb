class AddEndDateToEvents < ActiveRecord::Migration
  def change
    rename_column :events, :date, :begins_at
    reversible do |dir|
      dir.up do
        change_column :events, :begins_at, :datetime
      end
      dir.down do
        change_column :events, :begins_at, :date
      end
    end
    add_column :events, :ends_at, :datetime, after: :begins_at, null: false
    reversible do |dir|
      dir.up do
        Event.update_all('ends_at = begins_at')
      end
    end
  end
end
