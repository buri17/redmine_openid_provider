require 'pathname'

require "openid"
require "openid/consumer/discovery"
require 'openid/extensions/sreg'
require 'openid/extensions/pape'
require 'openid/store/filesystem'

class OpenIdProviderController < ApplicationController

  include OpenIdProviderHelper
  include OpenID::Server
  layout nil

  protect_from_forgery only: :confirm
  before_filter :find_user, :only => [:user_page, :user_xrdp]
  skip_before_filter :check_if_login_required

  rescue_from ProtocolError, with: :handle_protocol_error

  def handle_direct_request
    open_id_request = server.decode_request(params)
    open_id_response = server.handle_request(open_id_request)
    render_response(open_id_response)
  end

  def checkid_setup
    open_id_request = server.decode_request(params)
    if !User.current.logged?
      redirect_to_login_page
    elsif !open_id_request.id_select && !owned_by_login_user?(open_id_request.identity)
      render_response open_id_request.answer(false)
    elsif !authorized?(open_id_request)
      show_confirm_page(open_id_request)
    else
      render_response build_success_answer(open_id_request)
    end
  end

  def checkid_immediage
    open_id_request = server.decode_request(params)
    if !User.current.logged? || !authorized?(open_id_request)
      render_response open_id_request.answer(false)
    else 
      render_response build_success_answer(open_id_request)
    end
  end

  def index
    response.headers['X-XRDS-Location'] = url_for(:controller=>'open_id_provider', :action=>'idp_xrds', :only_path=>false)
  end

  def idp_xrds
    respond_to do |format|
      format.xrds {
        render :template => 'open_id_provider/idp', :content_type => 'application/xrds+xml'
      }
    end
  end

  def confirm
    open_id_request = session[:last_open_id_request]
    session[:last_open_id_request] = nil

    if params[:yes].nil?
      redirect_to open_id_request.cancel_url
    else
      if session[:approvals]
        session[:approvals] << open_id_request.trust_root
      else
        session[:approvals] = [open_id_request.trust_root]
      end
      render_response build_success_answer(open_id_request)
    end
  end

  def user_page
    accept = request.env['HTTP_ACCEPT']
    if accept and accept.include?('application/xrds+xml')
      user_xrds
    else
      xrds_url = url_for(:controller=>'open_id_provider',:id=>params[:id], :action=>'user_xrds', :only_path=>false)
      response.headers['X-XRDS-Location'] = xrds_url
    end
  end

  def user_xrds
    respond_to do |format|
      format.xrds {
        render :template => 'open_id_provider/user', :content_type => 'application/xrds+xml'
      }
    end
  end

  protected

  def show_confirm_page(open_id_request)
    session[:last_open_id_request] = open_id_request
    @open_id_request = open_id_request
    render :template => 'open_id_provider/confirm'
  end

  def server
    if @server.nil?
      server_url = url_for :action => 'index', :only_path => false
      dir = Rails.root.join('db').join('openid-store')
      store = OpenID::Store::Filesystem.new(dir)
      @server = Server.new(store, server_url)
    end
    return @server
  end

  def approved(trust_root)
    return false if session[:approvals].nil?
    return session[:approvals].member?(trust_root)
  end

  def authorized?(open_id_request)
    return ((open_id_request.id_select || owned_by_login_user?(open_id_request.identity)) && approved(open_id_request.trust_root))
  end

  def owned_by_login_user?(identity)
    identity == url_for_user(User.current.id)
  end

  def add_sreg(open_id_request, open_id_response)
    # check for Simple Registration arguments and respond
    sregreq = OpenID::SReg::Request.from_openid_request(open_id_request)

    return if sregreq.nil?
    # In a real application, this data would be user-specific,
    # and the user should be asked for permission to release
    # it.
    sreg_data = {
      'nickname' => User.current.login,
      'fullname' => User.current.name,
      'email' => User.current.mail,
      'language' => User.current.language,
      'timezone' => User.current.time_zone.nil? ? 
        nil : User.current.time_zone.tzinfo.identifier
    }
    
    sregresp = OpenID::SReg::Response.extract_response(sregreq, sreg_data)
    open_id_response.add_extension(sregresp)
  end

  def add_pape(open_id_request, open_id_response)
    papereq = OpenID::PAPE::Request.from_openid_request(open_id_request)
    return if papereq.nil?
    paperesp = OpenID::PAPE::Response.new
    paperesp.nist_auth_level = 0 # we don't even do auth at all!
    open_id_response.add_extension(paperesp)
  end

  def render_response(open_id_response)
    web_response = server.encode_response(open_id_response)

    case web_response.code
    when HTTP_OK
      render :text => web_response.body, :status => 200

    when HTTP_REDIRECT
      redirect_to web_response.headers['location']

    else
      render :text => web_response.body, :status => 400
    end
  end

  def handle_protocol_error(e)
    render :text => e.to_s, :status => 500
  end

  def handle_unverified_request
  end

  def redirect_to_login_page
    # Extract only the basic url parameters on non-GET requests
    if request.get?
      url = url_for(params)
    else
      url = url_for(:controller => params[:controller], :action => params[:action], :id => params[:id], :project_id => params[:project_id])
    end
    redirect_to :controller => "account", :action => "login", :back_url => url
  end

  def build_success_answer(open_id_request)
    open_id_response = open_id_request.answer(true, nil, url_for_user(User.current.id))
    
    add_sreg(open_id_request, open_id_response)
    add_pape(open_id_request, open_id_response)
    open_id_response
  end

  def find_user
    if params[:id] == 'current'
      @user = User.current
    else
      @user = User.find(params[:id])
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
