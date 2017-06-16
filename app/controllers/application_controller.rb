require 'uri'

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  rescue_from TdbException do |mes|
    render json: mes.to_h, status: 400
  end

  def index
    return redirect_to '/account' if session.key?(:frankiz_id)
  end

  def account
    frankiz_id = session[:frankiz_id].to_i
    @account = Account.where.not(trigramme: nil).find_by(frankiz_id: frankiz_id)
    return redirect_to '/unknown' if @account.nil?
    KeenEvent.publish(:account_view, @account.as_json)
    @transactions = Transaction.where(id: @account.id).where('price != 0').where('date > ?', Time.current - 1.week)
      .includes(:receiver)
      .order(date: :desc).limit(100)
  end

  def unknown
    KeenEvent.publish(:unknown_account, frankiz_id: session[:frankiz_id].to_i)
    session.delete(:frankiz_id)
    session.delete(:binets_admin)
  end

  def fkz_login
    if Rails.env.development?
      # We're gonna mock a Fkz response to be able to test locally
      response = {
        uid: '12368',
        hruid: 'thierry.deo',
        firstname: 'Thierry',
        lastname: 'Deo',
        nickname: 'Manouel',
        promo: 2010,
        promos: ['x2010'],
        binets_admin: { bobar: 'BôBar', bb: 'Binouze' },
      }.to_json
      timestamp = Time.current.to_i
      fkz_response = {
        response: response,
        timestamp: timestamp,
        location: '...',
        hash: Digest::MD5.hexdigest(timestamp.to_s + ENV['FKZ_KEY'] + response),
      }
      uri_params = URI.encode_www_form(fkz_response)
      return redirect_to "/fkz_logged?#{uri_params}"
    end

    timestamp = Time.current.to_i.to_s
    site = ENV['FKZ_SITE']
    location = '...'
    request = %w(names promo binets_admin).to_json
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
    response = JSON.parse(response)
    session[:frankiz_id] = response['uid']
    session[:binets_admin] = response['binets_admin'].select { |k, _| k == BOB }
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
    session.delete(:binets_admin)
    redirect_to '/'
  end

  private

  def not_found!
    fail ActionController::RoutingError, 'Not Found'
  end

  def require_bob_admin!
    not_found! unless session[:binets_admin].key?(BOB)
  end
end
