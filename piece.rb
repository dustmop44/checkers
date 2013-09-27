require 'colorize'

class InvalidMoveError < RuntimeError
end

class Piece
  SLIDE_MOVES_UP = [[-1, 1], [-1, -1]]
  SLIDE_MOVES_DOWN = [[1, 1], [1, -1]]
  JUMP_MOVES_UP = [[-2, 2], [-2, -2]]
  JUMP_MOVES_DOWN = [[2, 2], [2, -2]]
  PROMOTION_ROWS = {:black => 7, :red => 0}
  MARKS = {:pawn => "\u2b24 ", :king => "\u2605 "}
  
  attr_reader :color
  
  def initialize(board, color, king = false)
    @board = board
    @color = color
    @king = king
  end
  
  def render
    type = @king ? :king : :pawn
    print MARKS[type].colorize(:color => @color, :background => :white)
  end
  
  def perform_slide(dest_square)
    unless slide_moves.include?(dest_square)
      raise InvalidMoveError, "piece cannot move there"
    end
    @board.move(location, dest_square)
    promotion_check
    true
  end
  
  def perform_jump(dest_square)
    unless jump_moves.include?(dest_square)
      raise InvalidMoveError, "piece cannot jump there"
    end
    @board.capture_between(location, dest_square)
    @board.move(location, dest_square)
    promotion_check
    true
  end
  
  def dup(board)
    Piece.new(board, @color, @king)
  end
  
  def perform_moves(moves)
    if valid_move_seq?(moves)
      perform_moves!(moves)
    else
      raise InvalidMoveError, "move invalid"
    end
  end
  
  def location
    @board.piece_coord(self)
  end
  
  def can_jump?
    if jump_moves.count > 0
      return true
    else
      return false
    end
  end
  
  def jump_moves
    unless king?
      jump_vectors = (@color == :black) ? JUMP_MOVES_DOWN : JUMP_MOVES_UP
    else
      jump_vectors = JUMP_MOVES_DOWN + JUMP_MOVES_UP
    end
    
    valid_jump_moves = valid_jumps(jump_vectors)
    
    all_jump_moves = []
    valid_jump_moves.each do |jump_move|
      rec_jump_moves = piece_at_test_move(jump_move).jump_moves
      
      return valid_jump_moves if rec_jump_moves.empty? #base case
      
      rec_jump_moves.each do |rec_jump_move|
        all_jump_moves << [jump_move] + [rec_jump_move]
      end
    end
    all_jump_moves
  end
  
  protected
  
  def perform_moves!(moves)
    jumps_only = (moves.count > 1) ? true : false
    moves.each do |move|
      if slide_moves.include?(move)
        raise InvalidMoveError, "Piece must jump" if jumps_only
        perform_slide(move)
      elsif jump_moves.include?(move)
        perform_jump(move)
      else
        raise InvalidMoveError, "Move to #{move} not possible"
      end
    end
  end
  
  private
  
  def king?
    @king
  end
  
  def valid_jumps(jump_vectors)
    jump_vectors = jump_vectors.dup
    
    #gets vectors for squares being jumped over
    jumped_squares = jump_vectors.map { |m| m.map { |c| c / 2 } }
  
    #adds vectors to current location
    poss_jump_moves = resulting_locations(jump_vectors)
    jumped_squares = resulting_locations(jumped_squares)
    
    poss_jump_moves.zip(jumped_squares).select do |move|
      valid_jump_move?(move)
    end.map do |move|
      dest, between = move
      dest
    end
  end
  
  def valid_jump_move?(move)
    #requires a zipped destination and between square
    dest, between = move
    on_board?(dest) &&
      @board.empty?(dest) &&
      !@board.empty?(between) && 
      @board[between].color != @color
  end
  
  def piece_at_test_move(move)
    test_board = @board.dup
    test_board.move(location, move)
    test_board[move]
  end
  
  def slide_moves
    unless king?
      slide_moves = (@color == :black) ? SLIDE_MOVES_DOWN : SLIDE_MOVES_UP
    else
      slide_moves = SLIDE_MOVES_DOWN + SLIDE_MOVES_UP
    end
    
    resulting_locations(slide_moves).select do |dest|
      on_board?(dest) && @board.empty?(dest)
    end
  end
  
  def resulting_locations(moves)
    moves.map do |move|
      row, col = location
      row_diff, col_diff = move

      [row + row_diff, col + col_diff]
    end
  end
  
  def on_board?(coord)
    coord.all? { |c| (0..7).cover?(c) }
  end
  
  def valid_move_seq?(moves)
    duped_board = @board.dup
    begin
      duped_board[location].perform_moves!(moves)
    rescue InvalidMoveError
      return false
    else
      return true
    end
  end
  
  def promotion_check
    return if @king
    row, col = location
    if row == PROMOTION_ROWS[@color]
      @king = true
    end
  end
end