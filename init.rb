Redmine::Plugin.register :redmine_openid_provider do
  name 'Redmine Openid Provider plugin'
  author 'MIURA Toru'
  description 'This plugin enables Redmine to behave as an Open ID provider.'
  version '1.0.0'
  url 'https://github.com/buri17/redmine_openid_provider'
  author_url 'https://github.com/buri17'
end

RedmineApp::Application.configure do
  config.middleware.delete OpenIdAuthentication
end

Mime::Type.register "application/xrds+xml", :xrds
