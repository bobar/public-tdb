class EventController < ApplicationController
  before_action :load_binet

  after_action :mark_comments_read, only: :event

  def event
    @event = Event.find_by(id: params[:event_id], binet_id: @binet[:id])
    not_found! if @event.nil?
    @transactions = EventTransaction.where(event_id: @event.id).order(updated_at: :desc)
    @comments = EventComment.where(event_id: @event.id).order(:created_at)
  end

  def mark_comments_read
    @comments.each { |c| c.mark_read_by(session[:frankiz_id]) } if params[:show_comments]
  end

  def binet_events
    @events = Event.where(binet_id: @binet[:id]).order(begins_at: :desc)
  end

  def create_event
    event_name = params[:name].to_s.strip
    begins_at = params[:begins_at]
    ends_at = params[:ends_at]
    submitter = Account.find_by(frankiz_id: session[:frankiz_id])
    fail TdbException, 'Le nom est obligatoire' if event_name.blank?
    fail TdbException, 'La date de debut est obligatoire' if begins_at.nil?
    fail TdbException, 'La date de fin est obligatoire' if ends_at.nil?
    fail TdbException, 'La date de debut doit être future' if begins_at < Time.current
    fail TdbException, 'La date de fin doit être après la date de début' if ends_at <= begins_at
    event = Event.create(binet_id: @binet[:id], name: event_name, begins_at: begins_at, ends_at: ends_at, requester_id: session[:frankiz_id])
    EventMailer.requested(event, @binet, submitter).deliver_now
    render_reload
  end

  def submit_event
    @event = Event.find_by(id: params[:event_id], binet_id: @binet[:id])
    filepath = "/tmp/#{@event.name} - #{@event.begins_at.strftime('%F %T')}.xlsx"
    submitter = Account.find_by(frankiz_id: session[:frankiz_id])
    fail TdbException, 'Tu n\'as pas l\'air connecté' if submitter.nil?
    fail TdbException, 'L\'évènement n\'est pas terminé' unless @event.finished?
    workbook = WriteXLSX.new(filepath)
    worksheet = workbook.add_worksheet
    worksheet.write(0, 0, 'Trigramme')
    worksheet.write(0, 1, 'Nom')
    worksheet.write(0, 2, 'Montant')
    @event.transactions.order(:updated_at).each_with_index do |transaction, i|
      account = Account.find_by(id: transaction.account_id)
      next if account.nil?
      worksheet.write(i + 1, 0, account.trigramme)
      worksheet.write(i + 1, 1, account.full_name)
      worksheet.write(i + 1, 2, transaction.price)
    end
    workbook.close
    EventMailer.submit(@event, @binet, submitter, filepath).deliver_now
    File.delete filepath
    @event.update(status: :submitted)
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
    @events = Event.includes(:requester).order(begins_at: :desc)
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
    EventComment.create(
      event_id: event.id,
      author_id: session[:frankiz_id],
      comment: params[:comment].strip,
      read_by: { session[:frankiz_id] => Time.current.utc }.to_json,
    )
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
