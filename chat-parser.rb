# Ye be warned: here be dragons.
require './commands'
require './battle'
require './chat-helpers.rb'


require 'faye/websocket'
require 'rest-client'
require 'open-uri'
require 'faraday'
require 'json'

TEAM = Faraday.get("https://gist.githubusercontent.com/NotBlizzard/e5e367d41e6894a8edd3/raw/0ffdcee8911d0e11c0cff9ba3c234cb93c8a29f6/team").body

class Bot
  include ChatHelpers
  attr_accessor :ws,:room, :user, :rooms, :server, :owner, :symbol, :log, :plugins
  @cleverbot = CleverBot.new
  # Yes, I know this is a global variable. I use it for accessing battle information while it is running.
  $battles = {}
  $start_time = ''

  def initialize(user, pass = '', rooms, server, owner, symbol, log, plugins)
    @room = ""
    @ws = ''
    @challenged = false
    @plugins = plugins
    @server = server
    @symbol = symbol
    @owner = owner
    @started = Time.now.to_i
    @rooms = rooms
    @pass = pass
    @user = user
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
      event.data.split("\n").each do |m|
        if m[0] == '>'
          @room = m.split('>')[1].strip
        end
        @time = Time.now.to_i

        puts m if @log

        if $start_time < @time# +1 to factor in delay.
          @plugins.each do |plugin|
            if m =~ plugin.match
              @ws.send("#{@room}|#{plugin.new.do(m)}")
            end
          end
        end

        message = m.split('|')
        battleroom = @room[/\d+/]

        if $battles.keys.include? battleroom
          $battles[battleroom.to_s].run(@ws, m, @room)
        end

        case message[1]
        when 'challstr'
          login(@user, @pass, message[2], message[3], @ws)

        when 'c'
          user = message[2]
          if message[3][0] == @symbol
            send_battle_command(message, @room, user, @symbol, @ws)
          end

        when 'c:'
          user = message[3].downcase
          @time = message[2].to_i
          if message[4][0] == @symbol and $start_time < @time
            send_command(message, @room, user, @symbol, @ws)
          end

        when 'updateuser'
          @rooms.each { |r| @ws.send("|/join #{r}") }

        when 'tournament'
          tournament_helper(@room, message[3], @ws)

        when 'player'
          battleroom = @room[/\d+/]
          unless $battles.keys.include? battleroom.to_s
            $battles[battleroom.to_s] = Battle.new(@tier,@challenged)
          end

        when 'updatechallenges'
          data= JSON.parse(message[2])
          challenges_from = data['challengesFrom'].keys[0].to_s
          tier = data['challengesFrom'][challenges_from]
          unless tier == nil and challenges_from == ""
            @tier, @challenged = battle_helper(message[2], @ws)
          end
        end
      end
    end
  end
end
