class Account < ActiveRecord::Base
  has_many :transactions, class_name: :Transaction, foreign_key: :id

  enum status: { x_platal: 0, x_ancien: 1, binet: 2, personnel: 3, etudiant_non_x: 4, autre: 5 }

  DEFAULT_BANK_TRIGRAMME = 'BOB'.freeze

  def self.search(term)
    return where(trigramme: term) if term.size == 3
    terms = term.gsub(/[^a-zA-Z0-9]/, ' ').split(' ')
    clause = terms.map do |t|
      "(LOWER(name) LIKE #{connection.quote('%' + t + '%')} OR LOWER(first_name) LIKE #{connection.quote('%' + t + '%')})"
    end.join(' AND ')
    where(clause).where.not(trigramme: nil).order(promo: :desc, name: :asc, first_name: :asc)
  end

  def autocomplete_text(with_trigramme: true)
    text = ''
    text += "#{trigramme} - " if trigramme && with_trigramme
    text += "#{promo} " if promo && promo != 0
    text += "#{first_name} #{name}"
    text.html_safe
  end

  def full_name
    "#{first_name} #{name}"
  end

  def fkz_picture
    return if frankiz_id.nil?
    user = User.find_by(frankiz_id: frankiz_id)
    return unless user
    return if user.picture.nil?
    "https://www.frankiz.net/#{user.picture}"
  end

  def readable_status
    status.to_s.tr('_', ' ').capitalize
  end
end
