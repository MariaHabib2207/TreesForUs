ActiveAdmin.register UserSession do
  menu label: "User Sessions", priority: 2

  actions :index, :show

  filter :user_email, as: :string, label: "User Email"
  filter :country
  filter :city
  filter :browser
  filter :os
  filter :device_type
  filter :ip_address
  filter :last_active_at

  scope :all, default: true
  scope(:online) { |s| s.where('last_active_at > ?', 5.minutes.ago) }

  index do
    column :user
    column("Email") { |s| s.user&.email }
    column :ip_address
    column("Location") { |s| [s.city, s.region, s.country].compact.join(', ') }

    column("Device") do |s|
      parts = [s.device_brand, s.device_name, s.device_type].compact
      parts.any? ? parts.join(' ') : 'Unknown'
    end
    column("OS")       { |s| "#{s.os} #{s.os_version}".strip }
    column("Browser")  { |s| "#{s.browser} #{s.browser_version}".strip }
    column("Last Active") { |s| time_ago_in_words(s.last_active_at) + " ago" }
    column("Status") do |s|
      if s.last_active_at > 5.minutes.ago
        status_tag "Online", class: "yes"
      else
        status_tag "Offline", class: "no"
      end
    end
    actions
  end

  show do
    attributes_table do
      row :user
      row :ip_address
      row("Location")  { |s| [s.city, s.region, s.country].compact.join(', ') }
      row("Device")    { |s| "#{s.device_type} #{s.device_name}".strip }
      row("OS")        { |s| "#{s.os} #{s.os_version}".strip }
      row("Browser")   { |s| "#{s.browser} #{s.browser_version}".strip }
      row :last_active_at
      row :user_agent
      row :latitude
      row :longitude
    end
  end
end