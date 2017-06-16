class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.string :name, null: false
      t.date :date, null: false
      t.string :binet_id, null: false
      t.integer :requester_id, null: false
      t.boolean :approved, null: false, default: 0
      t.boolean :closed, null: false, default: 0
      t.timestamps
    end
  end
end
