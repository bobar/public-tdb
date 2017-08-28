Rails.application.routes.draw do
  root 'application#index'

  controller :account, path: 'account' do
    get 'search' => :search
  end

  controller :application do
    get '/account(/:account_id)' => :account
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
    post '/event/submit/:binet_id/:event_id' => :submit_event
    post '/event/status/:event_id/:new_status' => :change_status
    post '/event/log/:binet_id/:event_id' => :log
    post '/event/comment/:binet_id/:event_id' => :add_comment
  end
end
