class EventComment < ActiveRecord::Base
  belongs_to :author, class_name: :User, primary_key: :frankiz_id
end
