class GameInviteNotifier < Noticed::Event
  deliver_by :action_cable, channel: "GameChannel", stream: -> { recipient }, message: -> {
    {
      type: "game_invite",
      game_session_id: params[:game_session].id
    }
  }

  required_param :game_session

  def message
    "#{params[:game_session].player_x.full_name} invited you to play Tic-Tac-Toe"
  end

  def game_session_id
    params[:game_session].id
  end
end