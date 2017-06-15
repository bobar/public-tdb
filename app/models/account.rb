class Account < ActiveRecord::Base
  has_many :transactions, class_name: :Transaction, foreign_key: :id

  DEFAULT_BANK_TRIGRAMME = 'BOB'.freeze

  def full_name
    "#{first_name} #{name}"
  end
end
