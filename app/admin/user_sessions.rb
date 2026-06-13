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
    column("User") do |s|
      div style: "font-weight:600;" do
        s.user&.email
      end
    end

    column("IP Address") do |s|
      if ['::1', '127.0.0.1'].include?(s.ip_address)
        span style: "color:#999; font-style:italic; font-size:12px;" do
          "localhost (dev)"
        end
      else
        code style: "background:#f4f4f4; padding:2px 6px; border-radius:4px; font-size:12px;" do
          s.ip_address
        end
      end
    end

    column("Location") do |s|
      location = [s.city, s.region, s.country].compact.join(', ')
      if location.present?
        div do
          span "📍 ", style: "font-size:12px;"
          span location, style: "font-size:13px;"
        end
      else
        span "—", style: "color:#ccc;"
      end
    end

    column("Device") do |s|
      parts = [s.device_brand, s.device_name].compact.join(' ')
      type  = s.device_type

      icon = case type&.downcase
             when 'smartphone' then '📱'
             when 'tablet'     then '📟'
             when 'desktop'    then '🖥️'
             when 'bot'        then '🤖'
             else '💻'
             end

      div do
        div style: "font-size:13px; font-weight:500;" do
          "#{icon} #{parts.presence || 'Unknown'}"
        end
        div style: "font-size:11px; color:#999;" do
          type&.capitalize
        end
      end
    end

    column("OS") do |s|
      div do
        div style: "font-size:13px;" do
          s.os.presence || '—'
        end
        div style: "font-size:11px; color:#999;" do
          s.os_version.presence
        end
      end
    end

    column("Browser") do |s|
      div do
        div style: "font-size:13px;" do
          s.browser.presence || '—'
        end
        div style: "font-size:11px; color:#999;" do
          s.browser_version.presence
        end
      end
    end

    column("Last Active") do |s|
      div do
        div style: "font-size:13px;" do
          time_ago_in_words(s.last_active_at) + " ago"
        end
        div style: "font-size:11px; color:#999;" do
          s.last_active_at.strftime("%b %d, %Y %H:%M")
        end
      end
    end

    column("Status") do |s|
      if s.last_active_at > 5.minutes.ago
        span style: "background:#2ecc71; color:#fff; padding:3px 10px; border-radius:12px; font-size:11px; font-weight:600;" do
          "● Online"
        end
      else
        span style: "background:#f0f0f0; color:#999; padding:3px 10px; border-radius:12px; font-size:11px; font-weight:600;" do
          "○ Offline"
        end
      end
    end

    actions
  end

  show do
    attributes_table do
      row("User")     { |s| s.user&.email }
      row("Status") do |s|
        if s.last_active_at > 5.minutes.ago
          span style: "background:#2ecc71; color:#fff; padding:3px 10px; border-radius:12px; font-size:11px; font-weight:600;" do
            "● Online"
          end
        else
          span style: "background:#f0f0f0; color:#999; padding:3px 10px; border-radius:12px; font-size:11px;" do
            "○ Offline"
          end
        end
      end
      row("IP Address") do |s|
        code style: "background:#f4f4f4; padding:2px 8px; border-radius:4px;" do
          s.ip_address
        end
      end
      row("Location")  { |s| "📍 #{[s.city, s.region, s.country].compact.join(', ')}" }
      row("Device")    { |s| "#{s.device_brand} #{s.device_name} (#{s.device_type})".strip }
      row("OS")        { |s| "#{s.os} #{s.os_version}".strip }
      row("Browser")   { |s| "#{s.browser} #{s.browser_version}".strip }
      row("Last Active") { |s| "#{time_ago_in_words(s.last_active_at)} ago — #{s.last_active_at.strftime('%b %d, %Y %H:%M')}" }
      row("Coordinates") { |s| "#{s.latitude}, #{s.longitude}" if s.latitude }
      row("User Agent") do |s|
        div style: "font-size:11px; color:#666; word-break:break-all;" do
          s.user_agent
        end
      end
    end
  end
end