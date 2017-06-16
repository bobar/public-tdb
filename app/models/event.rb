class Event < ActiveRecord::Base
  belongs_to :requester, class_name: :Account, primary_key: :frankiz_id

  def status
    return 'Terminé' if closed
    return 'Approuvé' if approved
    'En attente d\'approbation'
  end
end
