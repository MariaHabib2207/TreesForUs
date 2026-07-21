class GameSession < ApplicationRecord
  belongs_to :player_x, class_name: "User"
  belongs_to :player_o, class_name: "User"
  belongs_to :winner, class_name: "User", optional: true

  WIN_LINES = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8],
    [0, 3, 6], [1, 4, 7], [2, 5, 8],
    [0, 4, 8], [2, 4, 6]
  ].freeze

  ACTIVE_STATUSES = %w[pending active].freeze

  scope :for_user, ->(user) { where("player_x_id = :id OR player_o_id = :id", id: user.id) }

  def self.between(user_a, user_b, statuses: ACTIVE_STATUSES)
    for_user(user_a)
      .where(status: statuses)
      .where(
        "(player_x_id = :a AND player_o_id = :b) OR (player_x_id = :b AND player_o_id = :a)",
        a: user_a.id, b: user_b.id
      )
      .first
  end

  def board_array
    board.chars
  end

  def player_for(user)
    return "x" if player_x_id == user.id
    return "o" if player_o_id == user.id

    nil
  end

  def opponent_for(user)
    player_x_id == user.id ? player_o : player_x
  end

  def current_turn_player
    turn == "x" ? player_x : player_o
  end

  def my_turn?(user)
    status == "active" && player_for(user) == turn
  end

  def make_move!(index, symbol)
    return false unless status == "active"
    return false unless turn == symbol
    return false unless board[index] == "-"

    new_board = board.dup
    new_board[index] = symbol.upcase
    self.board = new_board

    if winning_line?
      self.status = "finished"
      self.winner = symbol == "x" ? player_x : player_o
    elsif board.exclude?("-")
      self.status = "finished"
    else
      self.turn = symbol == "x" ? "o" : "x"
    end

    save!
  end

def cancellable_by?(user)
  status == "pending" && player_x_id == user.id
end

  def winning_line?
    WIN_LINES.any? do |line|
      values = line.map { |i| board[i] }
      values.uniq.size == 1 && values.first != "-"
    end
  end
end