
require 'faye/websocket'
require 'open-uri'
require 'faraday'
require 'json'

require './commands'
require './battle'
require './chat-helpers'


$start_time = ''
$ladder = false
$ladder_tier = 'challengecup1v1'

class Bot
  include ChatHelpers
  attr_accessor :ws,:room, :user, :rooms, :server, :owner, :symbol, :log, :plugins, :room_join_time
  # Yes, I know this is a global variable. I use it for accessing battle information while it is running.
  $battles = {}

  def initialize(user, pass = '', rooms, server, owner, symbol, log, plugins)
    @room = ""
    @room_joined = {}
    @ws = ''
    @prev_message = ''
    @challenged = false
    @plugins = plugins
    @server = server
    @symbol = symbol
    @owner = owner
    @rooms = rooms
    @pass = pass
    @user = user
    @room = ""
    @tier = ''
    @joined = false
    @log = log
  end

  def say(room, msg)
    @ws.send("#{room}|#{msg}")
    ""
  end

  def run
    $start_time = Time.now.to_i
    @ws = Faye::WebSocket::Client.new("ws://#{@server}/showdown/websocket")
    @ws.on :message do |event|
      event.data.split("\n").each do |message|
        if message[0] == '>'
          @room = message.split('>')[1].strip
        end

        puts message if @log

        begin
          time = message[2].to_i
        rescue
        end

        if @room_joined[room] == true
          @plugins.each do |plugin|
            unless (message.match(plugin.match)).nil?
              @ws.send("#{@room}|#{plugin.new.do(message)}")
            end
          end
        end

        messages = message.split('|')
        battleroom = @room[/\d+/]

        if $battles.keys.include? battleroom
          $battles[battleroom.to_s].run(@ws, message, @room)
        end

        case messages[1]
        when 'challstr'
          login(@user, @pass, messages[2], messages[3], @ws)

        when 'c'
          user = messages[2]
          if messages[3][0] == @symbol
            send_battle_command(messages, @room, user, @symbol, @ws)
          end

        when 'c:'
          @room = 'lobby' unless @prev_message.include? ">"
          user = messages[3].downcase
          time = messages[2].to_i
          puts "time of msg was #{time} and time now is #{Time.now.to_i}"
          if messages[4][0] == @symbol and @room_joined[@room] == true
            if @room == 'lobby'
              send_command(messages, '', user, @symbol, @ws)
            else
              send_command(messages, @room, user, @symbol, @ws)
            end
          end

        when 'updateuser'
          @rooms.each do |r|
            @ws.send("|/join #{r}")
          end

        when 'J'
          unless (messages[2].match(@user)).nil?
            @room_joined[@prev_message.split('>')[1]] = true
          end

        when 'player'
          battleroom = @room[/\d+/]
          unless $battles.keys.include? battleroom.to_s
            $battles[battleroom.to_s] = Battle.new(@tier,@user)
          end

        when 'updatechallenges'
          data = JSON.parse(messages[2])
          @tier, @challenged = battle_helper(messages[2], @ws) unless data['challengeTo'].nil? and data['challengesFrom'].empty?
        end

        @prev_message = message
      end
    end
  end
end
