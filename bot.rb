require './chat-parser.rb'

class Bot
  $battles = Hash.new {|h, k| h[k] = Hash.new {|h,k| h[k] = Hash.new}}
  def initialize(user, pass = '', rooms, server, owner, symbol, log)
    @room = ""
    @battles = Array.new
    @server = server
    @symbol = symbol
    @owner = owner
    @rooms = rooms
    @pass = pass
    @user = user
    @log = log
  end

  def go
    chat = ChatParser.new(@user, @pass, @rooms, @server, @owner, @symbol, @log)
    chat.run
  end
end
