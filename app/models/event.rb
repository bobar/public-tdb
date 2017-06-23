class Event < ActiveRecord::Base
  belongs_to :requester, class_name: :User, primary_key: :frankiz_id
  has_many :comments, class_name: :EventComment

  enum status: {
    requested: 0,
    denied: 1,
    approved: 2,
    opened: 3,
    finished: 4,
    submitted: 5,
    paid: 6,
  }

  STATUSES = {
    requested: 'En atente d\'approbation',
    denied: 'Refusé',
    approved: 'Approuvé',
    opened: 'En cours',
    finished: 'Terminé',
    submitted: 'Soumis pour paiement',
    paid: 'Payé',
  }.with_indifferent_access.freeze

  STATUS_CHANGE = {
    requested: { approved: 'Approuver', denied: 'Refuser' },
    denied: {},
    approved: { opened: 'Ouvrir' },
    opened: { finished: 'Fermer' },
    finished: { opened: 'Rouvrir', submitted: 'Soumettre pour paiement' },
    submitted: { paid: 'Paiement effectué' },
    paid: {},
  }.with_indifferent_access.freeze

  def readable_status
    STATUSES[status]
  end
end
