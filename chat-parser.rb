# Ye be warned: here be dragons.
require './commands'
require './battle'
require './chat-helpers'

require 'faye/websocket'
require 'cleverbot-api'
require 'rest-client'
require 'open-uri'
require 'faraday'
require 'json'

TEAM = Faraday.get("https://gist.githubusercontent.com/NotBlizzard/e5e367d41e6894a8edd3/raw/0ffdcee8911d0e11c0cff9ba3c234cb93c8a29f6/team").body

class ChatParser
  include ParserHelpers
  attr_accessor :ws,:room
  @cleverbot = CleverBot.new
  # Most complex hash ever.
  # Yes, I know this is a Global Variable. I use it for testing the bot while it is running.

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

  def say(room, msg)
    @ws.send("#{room}|#{msg}")
    ""
  end

  def run
    @ws = Faye::WebSocket::Client.new("ws://#{@server}/showdown/websocket")
    @ws.on :message do |event|
      event.data.split("\n").each do |m|
        if m[0] and m[0][0] == '>'
          @room = m.split('>')[1].strip
        end

        puts m if @log

        message = m.split('|')
        battleroom = @room[/\d+/]

        if $battles.keys.include? battleroom
          $battles[battleroom.to_s].run(@ws, m, @room)
        end

        case message[1]
        when 'challstr'
          login(@user, @pass, message[2], message[3], @ws)

        when 'c'
          room = message[1]
          if message[3][0] == @symbol
            send_battle_command(message, @room, user, @symbol, @ws)
          end

        when  'c:'
          user = m[3].downcase
          time = m[2].to_i
          unless time < Time.now.to_i
            if m[4][0] == @symbol
              send_command(message, @room, user, @symbol, @ws)
            end
          end

        when 'updateuser'
          @rooms.each { |r| @ws.send("|/join #{r}") }

        when 'player'
          battleroom = @room[/\d+/]
          unless $battles.keys.include? battleroom
            $battles[battleroom.to_s] = Battle.new(@tier, true)
          end

        when 'updatechallenges'
          @tier = battle_helper(message[2], ws)
        end
      end
    end
  end
end

