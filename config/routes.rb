# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

match 'openid', to: 'open_id_provider#checkid_setup',
  constraints: lambda { |request|
    request.query_parameters["openid.mode"] == "checkid_setup" }

match 'openid', to: 'open_id_provider#checkid_immediate',
  constraints: lambda { |request|
    request.query_parameters["openid.mode"] == "checkid_immediate" }

match 'openid', to: 'open_id_provider#handle_direct_request', via: 'POST'

match 'openid', :to => 'open_id_provider#index'
match 'openid/xrds', :to => 'open_id_provider#idp_xrds', :defaults => { :format => 'xrds' }
match 'openid/confirm', :to => 'open_id_provider#confirm'
match 'openid/user/:id', :to => 'open_id_provider#user_page'
match 'openid/user/:id/xrds', :to => 'open_id_provider#user_xrds', :defaults => { :format => 'xrds' }
