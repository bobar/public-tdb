class AddStatusToEvents < ActiveRecord::Migration
  def change
    add_column :events, :status, :integer, after: :requester_id, null: false, default: 0
    remove_column :events, :approved
    remove_column :events, :closed
  end
end
