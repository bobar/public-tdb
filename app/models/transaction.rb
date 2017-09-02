class Transaction < ActiveRecord::Base
  belongs_to :buyer, class_name: :Account, foreign_key: :buyer_id
  belongs_to :receiver, class_name: :Account, foreign_key: :receiver_id
end
