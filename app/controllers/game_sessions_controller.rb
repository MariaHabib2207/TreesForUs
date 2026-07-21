class GameSessionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_game_session, only: [ :show, :accept, :decline, :cancel, :move, :destroy ]

  def index
    @game_sessions = GameSession.for_user(current_user).order(updated_at: :desc)
  end

  def create
    opponent = User.find(params[:opponent_id])

    existing = GameSession.between(current_user, opponent)
    if existing
      return render json: { status: "exists", game_session_id: existing.id }, status: :unprocessable_entity
    end

    @game_session = GameSession.create!(player_x: current_user, player_o: opponent, status: "pending")
    GameInviteNotifier.with(game_session: @game_session).deliver(opponent)
    render json: { game_session_id: @game_session.id, status: @game_session.status }
  end

  def show
  end

  def accept
    return head :forbidden unless @game_session.player_o_id == current_user.id

    @game_session.update!(status: "active")
    GameChannel.broadcast_to(@game_session, { type: "game_started", game_session_id: @game_session.id })
    GameChannel.broadcast_to(@game_session.player_x, { type: "game_started", game_session_id: @game_session.id })

    respond_to do |format|
      format.html { redirect_to game_session_path(@game_session) }
      format.json { render json: { status: "active", redirect_url: game_session_path(@game_session) } }
    end
  end

  def decline
    return head :forbidden unless @game_session.player_o_id == current_user.id

    @game_session.update!(status: "declined")
    GameChannel.broadcast_to(@game_session.player_x, { type: "game_declined", game_session_id: @game_session.id })

    respond_to do |format|
      format.html { redirect_to notifications_path }
      format.json { render json: { status: "declined" } }
    end
  end

  def cancel
    return head :forbidden unless @game_session.cancellable_by?(current_user)

    @game_session.destroy!
    respond_to do |format|
      format.html { redirect_to game_sessions_path, notice: "Invite cancelled." }
      format.json { render json: { status: "cancelled" } }
    end
  end

  def move
    symbol = @game_session.player_for(current_user)
    return head :forbidden unless symbol

    if @game_session.make_move!(params[:index].to_i, symbol)
      GameChannel.broadcast_to(@game_session, {
        type: "move_made", board: @game_session.board, turn: @game_session.turn,
        status: @game_session.status, winner_id: @game_session.winner_id
      })
      render json: { status: "ok" }
    else
      render json: { status: "invalid_move" }, status: :unprocessable_entity
    end
  end

  def destroy
    unless [ @game_session.player_x_id, @game_session.player_o_id ].include?(current_user.id)
      return head :forbidden
    end

    @game_session.destroy!
    redirect_to game_sessions_path, notice: "Game room deleted."
  end

  private

  def set_game_session
    @game_session = GameSession.find(params[:id])
  end
end
