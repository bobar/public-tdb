require 'uri'

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :set_raven_context
  before_action :guess_opened!

  rescue_from TdbException do |mes|
    render json: mes.to_h, status: :bad_request
  end

  def index
    return redirect_to '/account' if session.key?(:frankiz_id)
  end

  def account
    frankiz_id = session[:frankiz_id].to_i
    @account = if params.key?(:account_id)
                 return redirect_to '/account' unless session[:admin]
                 Account.find(params[:account_id].to_i)
               else
                 Account.where.not(trigramme: nil).find_by(frankiz_id: frankiz_id)
               end
    return redirect_to '/unknown' if @account.nil?
    KeenEvent.publish(:account_view, @account.as_json) unless params.key?(:account_id)
    @transactions = Transaction.where('buyer_id = ? OR receiver_id = ?', @account.id, @account.id)
      .where('amount != 0').where('date > ?', Time.current - 1.week)
      .includes(:receiver)
      .includes(:buyer)
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
    session[:frankiz_id] = response['uid'].to_i
    session[:binets_admin] = response['binets_admin'] || {}
    session[:admin] = session[:binets_admin].key?(BOB)
    redirect_to '/'
  end

  def issue
    client = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])
    body = params[:body]
    user = User.find_by(frankiz_id: session[:frankiz_id])
    body += "\nCreated by #{user.try(:full_name)}, frankiz_id: #{session[:frankiz_id]}\n"
    client.create_issue('bobar/public-tdb', 'New issue', body)
  end

  def logout
    session.delete(:frankiz_id)
    session.delete(:binets_admin)
    session.delete(:admin)
    redirect_to '/'
  end

  private

  def not_found!
    fail ActionController::RoutingError, 'Not Found'
  end

  def require_bob_admin!
    not_found! unless session[:admin]
  end

  def guess_opened!
    transactions = Transaction.where(receiver_id: Account::DEFAULT_BANK_ID).last(10)
    @opened = transactions &&
              transactions.map(&:date).min >= Time.current - 30.minutes
  end

  def set_raven_context
    Raven.user_context(id: session[:frankiz_id])
    Raven.extra_context(params: params.to_unsafe_h, url: request.url)
  end
end
