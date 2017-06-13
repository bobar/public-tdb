class Transaction < ActiveRecord::Base
  belongs_to :buyer, class_name: :Account, foreign_key: :id
  belongs_to :receiver, class_name: :Account, foreign_key: :id2
end
