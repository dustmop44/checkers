require_relative 'negamax'

class ComputerPlayer
  include Negamax
  
  def initialize(color, depth)
    @color = color
    @depth = depth
  end
  
  def play_turn(board)
    move = best_move(board)
    puts "#{@color}: #{move}"
    play_move(board, move)
  end
  
  def play_move(board, move_seq)
    moving_piece = move_seq.shift    
    board[moving_piece].perform_moves(move_seq)
  end
  
  def all_moves(board)
    moves = []
    pieces(board).each do |piece|
      piece.all_move_seqs.each { |m| moves << m.unshift(piece.location) }
    end
    moves
  end
  
  def possible_jump_moves(board)
    pieces = board.pieces.select { |p| p.color == @color }
    all_moves = []
    pieces.each do |piece|
      piece.jump_moves.each do |move|
        board_copy = board.dup
        
        all_moves << [piece.location, move] 
      end
    end
  end
  
  def pieces(board)
    board.pieces.select { |p| p.color == @color }
  end
end