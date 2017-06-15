class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def index
    return redirect_to '/account' if session.key?(:frankiz_id)
  end

  def account
    frankiz_id = session[:frankiz_id].to_i
    @account = Account.find_by(frankiz_id: frankiz_id)
    return redirect_to '/unknown' if @account.nil?
    KeenEvent.publish(:account_view, @account.as_json)
    @transactions = Transaction.where(id: @account.id).where('price != 0').where('date > ?', Time.current - 1.week)
      .includes(:receiver)
      .order(date: :desc).limit(100)
  end

  def unknown
    KeenEvent.publish(:unknown_account, frankiz_id: frankiz_id)
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

  def issue
    client = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])
    body = params[:body]
    body += "\nFrankiz_id: #{session[:frankiz_id]}\n"
    client.create_issue('bobar/public-tdb', 'New issue', body)
  end

  def logout
    session.delete(:frankiz_id)
    redirect_to '/'
  end
end
