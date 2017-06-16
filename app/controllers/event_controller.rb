class EventController < ApplicationController
  before_action :load_binet

  def event
    @event = Event.find_by(id: params[:event_id], binet_id: @binet[:id], approved: true)
    not_found! if @event.nil?
    @transactions = EventTransaction.where(event_id: @event.id).order(updated_at: :desc)
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
    fail TdbException, 'L\'évènement n\'a pas été approuvé' unless event.approved
    fail TdbException, 'L\'évènement est terminé' if event.closed
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

  def approve_event
    require_bob_admin!
    Event.find(params[:event_id]).update(approved: true)
    render_reload
  end

  def close_event
    require_bob_admin!
    Event.find(params[:event_id]).update(closed: true)
    render_reload
  end

  def open_event
    require_bob_admin!
    Event.find(params[:event_id]).update(closed: false)
    render_reload
  end

  private

  def load_binet
    return unless params.key?(:binet_id)
    not_found! unless session[:binets_admin].key?(params[:binet_id])
    @binet = { id: params[:binet_id], name: session[:binets_admin][params[:binet_id]] }.with_indifferent_access
  end

  def render_reload
    respond_to do |format|
      format.js { return render text: 'location.reload();' }
    end
  end
end
