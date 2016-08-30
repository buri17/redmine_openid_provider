# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

post 'openid', to: 'open_id_provider#checkid_setup',
  constraints: lambda { |request|
    request.request_parameters["openid.mode"] == "checkid_setup" }

post 'openid', to: 'open_id_provider#checkid_immediate',
  constraints: lambda { |request|
    request.request_parameters["openid.mode"] == "checkid_immediate" }

post 'openid', to: 'open_id_provider#handle_direct_request'

get 'openid', :to => 'open_id_provider#index'
get 'openid/xrds', :to => 'open_id_provider#idp_xrds', :defaults => { :format => 'xrds' }
post 'openid/confirm', :to => 'open_id_provider#confirm'
get 'openid/user/:id', :to => 'open_id_provider#user_page'
get 'openid/user/:id/xrds', :to => 'open_id_provider#user_xrds', :defaults => { :format => 'xrds' }
