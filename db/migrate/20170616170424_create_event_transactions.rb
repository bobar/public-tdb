class CreateEventTransactions < ActiveRecord::Migration
  def change
    create_table :event_transactions do |t|
      t.integer :event_id, null: false
      t.integer :account_id, null: false
      t.string :trigramme, null: false, limit: 3
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.decimal :price, limit: 12, precision: 2, null: false
      t.timestamps
    end

    add_foreign_key :event_transactions, :events
  end
end
