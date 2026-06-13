# app/admin/dashboard.rb
ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: "Dashboard"

  content title: "Dashboard" do

    # ── Stat Cards ────────────────────────────────────────────
    div style: "display:flex; gap:16px; margin-bottom:24px;" do

      div style: "flex:1; background:#fff; border-radius:8px; padding:20px; box-shadow:0 1px 4px rgba(0,0,0,0.1); border-left:4px solid #2ecc71;" do
        h3 "🟢 Online Now", style: "margin:0 0 8px; font-size:13px; color:#666; text-transform:uppercase; letter-spacing:0.5px;"
        span UserSession.where('last_active_at > ?', 5.minutes.ago).count.to_s,
             style: "font-size:32px; font-weight:700; color:#2ecc71;"
      end

      div style: "flex:1; background:#fff; border-radius:8px; padding:20px; box-shadow:0 1px 4px rgba(0,0,0,0.1); border-left:4px solid #3498db;" do
        h3 "📊 Total Sessions", style: "margin:0 0 8px; font-size:13px; color:#666; text-transform:uppercase; letter-spacing:0.5px;"
        span UserSession.count.to_s,
             style: "font-size:32px; font-weight:700; color:#3498db;"
      end

      div style: "flex:1; background:#fff; border-radius:8px; padding:20px; box-shadow:0 1px 4px rgba(0,0,0,0.1); border-left:4px solid #9b59b6;" do
        h3 "👥 Total Users", style: "margin:0 0 8px; font-size:13px; color:#666; text-transform:uppercase; letter-spacing:0.5px;"
        span User.count.to_s,
             style: "font-size:32px; font-weight:700; color:#9b59b6;"
      end

    end

    # ── Breakdown Panels ──────────────────────────────────────
    columns do

      column do
        panel "📱 By Device" do
          device_colors = { "Desktop" => "#3498db", "Mobile" => "#2ecc71", "Tablet" => "#e67e22", "Bot" => "#e74c3c" }
          UserSession.group(:device_type).count.each do |device, count|
            color = device_colors[device] || "#95a5a6"
            div style: "display:flex; justify-content:space-between; align-items:center; padding:8px 0; border-bottom:1px solid #f0f0f0;" do
              span style: "display:flex; align-items:center; gap:8px;" do
                span style: "width:10px; height:10px; border-radius:50%; background:#{color}; display:inline-block;"
                span device.presence || "Unknown"
              end
              span count.to_s, style: "font-weight:600; color:#{color};"
            end
          end
        end
      end

      column do
        panel "🌍 Top Countries" do
          UserSession.group(:country).count.sort_by { |_, v| -v }.first(8).each do |country, count|
            total   = UserSession.count.to_f
            percent = total > 0 ? (count / total * 100).round(1) : 0
            div style: "margin-bottom:10px;" do
              div style: "display:flex; justify-content:space-between; margin-bottom:3px;" do
                span country.presence || "Unknown"
                span "#{count} (#{percent}%)", style: "color:#666; font-size:12px;"
              end
              div style: "background:#f0f0f0; border-radius:4px; height:6px;" do
                div style: "background:#3498db; width:#{percent}%; height:6px; border-radius:4px;"
              end
            end
          end
        end
      end

      column do
        panel "🌐 By Browser" do
          browser_colors = { "Chrome" => "#f39c12", "Firefox" => "#e74c3c", "Safari" => "#3498db", "Edge" => "#2ecc71" }
          UserSession.group(:browser).count.sort_by { |_, v| -v }.each do |browser, count|
            color = browser_colors[browser] || "#95a5a6"
            div style: "display:flex; justify-content:space-between; align-items:center; padding:8px 0; border-bottom:1px solid #f0f0f0;" do
              span style: "display:flex; align-items:center; gap:8px;" do
                span style: "width:10px; height:10px; border-radius:50%; background:#{color}; display:inline-block;"
                span browser.presence || "Unknown"
              end
              span count.to_s, style: "font-weight:600; color:#{color};"
            end
          end
        end
      end

    end
  end
end