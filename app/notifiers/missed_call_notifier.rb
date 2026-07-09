class MissedCallNotifier < Noticed::Event
  deliver_by :database
  deliver_by :action_cable do |config|
    config.channel = "NotificationChannel"
    config.stream = -> { recipient }
    config.message = -> {
      {
        title: "Missed call",
        body: "#{params[:caller].full_name} tried to call you",
        url: chatroom_path(params[:chatroom])
      }
    }
  end

  param :chatroom
  param :caller

  def message
    "#{params[:caller].full_name} tried to call you"
  end

  def url
    chatroom_path(params[:chatroom])
  end
end
