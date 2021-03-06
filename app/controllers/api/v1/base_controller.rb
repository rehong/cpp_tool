class Api::V1::BaseController < ApplicationController

  before_action :authenticate_user!
  attr_accessor :current_user

  protected

  def authenticate_user!
    authenticate
    return unauthenticated! unless @current_user
  end

  def authenticate
    #token, options = ActionController::HttpAuthentication::Token.token_and_options(request)
    #@current_user ||= User.first
    @current_user ||= user_in_payload Auth.payload(access_token)
  end

  def access_token
    request.headers["Authorization"] || params[:token] || cookies["accessToken"]
  end

  # transcode access token payload format
  def user_in_payload payload
    User.find(payload["uid"]) rescue nil
  end

  def payload_for_user user
    {uid: user.id}
  end

  def unauthenticated!
    #api_error(status: 401)
    render json: {error: '用户未验证', status: 401}, status: 401
  end




end
