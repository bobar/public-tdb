class EventController < ApplicationController
  before_action :load_binet

  def event
    @event = Event.find_by(id: params[:event_id], binet_id: @binet[:id])
    not_found! if @event.nil?
    @transactions = EventTransaction.where(event_id: @event.id).order(updated_at: :desc)
    @comments = EventComment.where(event_id: @event.id).order(:created_at)
  end

  def binet_events
    @events = Event.where(binet_id: @binet[:id]).order(date: :desc)
  end

  def create_event
    event_name = params[:name].to_s.strip
    event_date = params[:date]
    fail TdbException, 'Le nom est obligatoire' if event_name.blank?
    fail TdbException, 'La date est obligatoire' if event_date.nil?
    Event.create(binet_id: @binet[:id], name: event_name, date: event_date, requester_id: session[:frankiz_id])
    render_reload
  end

  def log
    account = Account.find_by(id: params[:account_id])
    event = Event.find_by(id: params[:event_id], binet_id: @binet[:id])
    fail TdbException, 'L\'évènement ne peut pas être retrouvé' if event.nil?
    fail TdbException, 'L\'évènement n\'est pas en cours' unless event.opened?
    fail TdbException, 'Pas de compte sélectionné' if account.nil?
    price = params[:amount].to_f.round(2)
    fail TdbException, 'Le montant doit être positif' unless price > 0
    EventTransaction.create(
      event_id: event.id,
      account_id: account.id,
      trigramme: account.trigramme,
      first_name: account.first_name,
      last_name: account.name,
      price: price,
    )
    render_reload
  end

  def admin
    require_bob_admin!
    @event_values = EventTransaction.select(:event_id, 'SUM(price) value').group(:event_id).index_by(&:event_id)
    @events = Event.includes(:requester).order(date: :desc)
  end

  def change_status
    require_bob_admin!
    e = Event.find(params[:event_id])
    status = e.status
    new_status = params[:new_status]
    fail TdbException, "Le statut ne peux pas être changé de #{Event::STATUSES[status]} à #{Event::STATUSES[new_status]}" unless
      Event::STATUS_CHANGE[status].key?(new_status)
    e.update(status: new_status)
    render_reload
  end

  def add_comment
    event = Event.find_by(id: params[:event_id], binet_id: @binet[:id])
    fail TdbException, 'L\'évènement ne peut pas être retrouvé' if event.nil?
    EventComment.create(event_id: event.id, author_id: session[:frankiz_id], comment: params[:comment].strip)
    render_reload
  end

  private

  def load_binet
    return unless params.key?(:binet_id)
    not_found! unless [params[:binet_id], 'bobar'].any? { |binet| session[:binets_admin].key?(binet) }
    @binet = { id: params[:binet_id], name: session[:binets_admin][params[:binet_id]] }.with_indifferent_access
  end

  def render_reload
    respond_to do |format|
      format.js { return render text: 'location.reload();' }
    end
  end
end
