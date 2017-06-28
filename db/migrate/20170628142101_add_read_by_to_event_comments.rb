class AddReadByToEventComments < ActiveRecord::Migration
  def change
    add_column :event_comments, :read_by, :text, after: :comment
  end
end
