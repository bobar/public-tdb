Rails.application.routes.draw do
  root 'application#index'

  controller :application do
    get '/account' => :account
    get '/fkz_login' => :fkz_login
    get '/fkz_logged' => :fkz_logged
    get '/logout' => :logout
    get '/unknown' => :unknown
    post '/issue' => :issue
  end

  controller :event do
    get '/events/admin' => :admin
    get '/binet/:binet_id' => :binet_events
    get '/event/:binet_id/:event_id' => :event
    post '/event/create/:binet_id' => :create_event
    post '/event/status/:event_id/:new_status' => :change_status
    post '/event/log/:binet_id/:event_id' => :log
  end

  controller :account, path: 'account' do
    get 'search' => :search
  end
end
