class CreateEventComments < ActiveRecord::Migration
  def change
    create_table :event_comments do |t|
      t.integer :event_id, null: false
      t.integer :author_id, null: false
      t.text :comment
      t.timestamps
    end
  end
end
