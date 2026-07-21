class GameChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_user
    stream_for game_session if params[:game_session_id].present?
  end

  private

  def game_session
    @game_session ||= GameSession.find(params[:game_session_id])
  end
end
