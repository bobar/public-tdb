Rails.application.routes.draw do
  root 'application#index'

  controller :application do
    get '/account' => :account
    get '/fkz_login' => :fkz_login
    get '/fkz_logged' => :fkz_logged
    get '/logout' => :logout
    get '/unknown' => :unknown
  end
end
