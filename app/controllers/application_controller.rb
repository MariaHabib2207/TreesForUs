class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  include PublicActivity::StoreController

  before_action :track_user_activity, if: :user_signed_in?
  before_action :set_current_user

  layout "application"

  def index
    if user_signed_in?
      redirect_to dashboard_path
    else
      redirect_to new_user_session_path
    end
  end

  private

  def set_current_user
    @user = current_user
  end

 def track_user_activity
  return unless current_user

  ua       = DeviceDetector.new(request.user_agent)
  ip       = real_ip
  location = IpLocationService.lookup(ip)

  session_data = {
    ip_address:      ip,
    user_agent:      request.user_agent,
    browser:         ua.name,
    browser_version: ua.full_version,
    os:              ua.os_name,
    os_version:      ua.os_full_version,
    device_type:     ua.device_type&.capitalize,
    device_name:     ua.device_name,
    device_brand:    ua.device_brand,
    last_active_at:  Time.current,
    city:            location[:city],
    region:          location[:region],
    country:         location[:country],
    latitude:        location[:latitude],
    longitude:       location[:longitude],
    zip:             location[:zip],
  }
  record = current_user.user_sessions.find_or_initialize_by(ip_address: ip)
  record.update!(session_data)
end

  def device_type(ua)
    return 'Mobile' if ua.device.mobile?
    return 'Tablet' if ua.device.tablet?
    return 'Bot'    if ua.bot?
    'Desktop'
  end

  def real_ip
  if Rails.env.development?
    "8.8.8.8"  # simulates real IP for testing
  else
    request.env['HTTP_X_FORWARDED_FOR']&.split(',')&.first&.strip ||
    request.env['HTTP_X_REAL_IP'] ||
    request.env['HTTP_CLIENT_IP'] ||
    request.remote_ip
  end
end
end