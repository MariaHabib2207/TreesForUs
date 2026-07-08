class MissedCallNotifier < Noticed::Event
  deliver_by :database

  param :chatroom
  param :caller

  def message
    "#{params[:caller].full_name} tried to call you"
  end

  def url
    chatroom_path(params[:chatroom])
  end
end