class ChangePriceColumn < ActiveRecord::Migration
  def up
    change_column :event_transactions, :price, :decimal, precision: 12, scale: 2
  end

  def down
    change_column :event_transactions, :price, :decimal, precision: 2, scale: 0
  end
end
