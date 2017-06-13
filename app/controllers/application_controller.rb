class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :sync_db

  def index
    return redirect_to '/account' if session.key?(:frankiz_id)
  end

  def account
    frankiz_id = session[:frankiz_id].to_i
    @account = Account.find_by(frankiz_id: frankiz_id)
    return redirect_to '/unknown' if @account.nil?
    @transactions = Transaction.where(id: @account.id).where('price != 0')
      .includes(:receiver)
      .order(date: :desc).limit(100)
  end

  def unknown
    session.delete(:frankiz_id)
  end

  def fkz_login
    timestamp = Time.current.to_i.to_s
    site = ENV['FKZ_SITE']
    location = '...'
    request = ['names', 'promo'].to_json
    digest = Digest::MD5.hexdigest(timestamp + site + ENV['FKZ_KEY'] + request)
    remote = 'https://www.frankiz.net/remote?timestamp=' + timestamp +
             '&site=' + site +
             '&location=' + location +
             '&hash=' + digest +
             '&request=' + request
    redirect_to remote
  end

  def fkz_logged
    timestamp = params[:timestamp]
    response = params[:response]
    digest = params[:hash]
    fail 'Délai dépassé' if (timestamp.to_i - Time.current.to_i).abs > 600
    fail 'Session compromise' if Digest::MD5.hexdigest(timestamp + ENV['FKZ_KEY'] + response) != digest
    response = JSON.load(response)
    session[:frankiz_id] = response['uid']
    redirect_to '/'
  end

  def logout
    session.delete(:frankiz_id)
    redirect_to '/'
  end

  private

  def sync_db
    return unless Rails.env.production?
    return if $last_sync && $last_sync > Time.current - 10.minutes
    $last_sync = Time.current
    Thread.new do
      Rails.logger.info 'Starting DB sync'
      database_path = SyncDb.fetch_database_from_gmail
      SyncDb.replace_database(database_path)
    end
  end
end
