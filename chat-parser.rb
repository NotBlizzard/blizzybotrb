# Ye be warned: here be dragons.
require './commands'
require './battle'
require './chat-helpers.rb'

require 'faye/websocket'
require 'rest-client'
require 'open-uri'
require 'faraday'
require 'json'

$start_time = ''
$ladder = false
$ladder_tier = 'challengecup1v1'

class Bot
  include ChatHelpers
  attr_accessor :ws,:room, :user, :rooms, :server, :owner, :symbol, :log, :plugins, :room_join_time
  @cleverbot = CleverBot.new
  # Yes, I know this is a global variable. I use it for accessing battle information while it is running.
  $battles = {}

  def initialize(user, pass = '', rooms, server, owner, symbol, log, plugins)
    @room = ""
    @room_join_time = {}
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
    @time = ''
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

        @time = Time.now.to_i

        puts message if @log

        unless @room_join_time[@room].nil?
          if Time.now.to_i > @room_join_time[@room].to_i
            @plugins.each do |plugin|
              if message =~ plugin.match
                @ws.send("#{@room}|#{plugin.new.do(message)}")
              end
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
          if messages[4][0] == @symbol and Time.now.to_i < time
            if @room == 'lobby'
              send_command(messages, '', user, @symbol, @ws)
            else
              send_command(messages, @room, user, @symbol, @ws)
            end
          end

        when 'updateuser'
          @rooms.each do |r|
            @ws.send("|/join #{r}")
            @room_join_time[r] = Time.now
          end

        #when 'tournament'
        #  tournament_helper(@room, messages[3], @ws)

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
