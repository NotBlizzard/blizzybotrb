# Ye be warned: here be dragons.
require './commands'
require './battle'

require 'faye/websocket'
require 'cleverbot-api'
require 'rest-client'
require 'faraday'
require 'open-uri'
require 'json'

TEAM_URL = "https://gist.githubusercontent.com/NotBlizzard/e5e367d41e6894a8edd3/raw/0ffdcee8911d0e11c0cff9ba3c234cb93c8a29f6/team"

class ShowdownBot
  attr_accessor :ladder, :ws, :battles, :room
  @battleroom = ''
  @br_num = @battleroom[/\d+/]
  @b_id = @battleroom[/(\d+)/]
  $cleverbot = CleverBot.new
  # Most complex hash ever.
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

  def say(room, msg)
    @ws.send("#{room}|#{msg}")
    ""
  end

  def run

    @ws = Faye::WebSocket::Client.new("ws://#{@server}/showdown/websocket")

    @ws.on :message do |event|
     # event.data.gsub!(/(^>)/, '')
      event.data.split("\n").each do |m|
        @tier = 'cc1v1' if ($ladder)
        d = m
        if m[0] and m[0][0] == '>'
          @room = m.split('>')[1].strip
        end
        puts m if @log
        m = m.split('|')
        battleroom = @room[/\d+/]
        if $battles.keys.include? battleroom
          $battles[battleroom.to_s].run(@ws, d, @room)
        end
        case m[1]
        when 'challstr'
          url = 'http://play.pokemonshowdown.com/action.php'
          if @pass.empty?
            data = Faraday.get url, {:act => 'getassertion', :userid => @user, :challengekeyid => m[2], :challenge => m[3]}
            @ws.send("|/trn #{@user},0,#{data.body}")
          else
            data = Faraday.post url, {:act => 'login', :name => @user, :pass => @pass, :challengekeyid => m[2], :challenge => m[3]}
            data = JSON.parse(data.body.split(']')[1])
            @ws.send("|/trn #{@user},0,#{data['assertion']}")
          end

        when 'pm'
          user = m[2]
          if m[4].downcase.include? @user.downcase
            @ws.send("|/pm #{user}, #{$cleverbot.think m[4]}")
          end


        when 'c'
          user = m[2]
          if m[3][0] == @symbol
            begin
              cmd = m[3].split(@symbol)[1].split(' ')[0]
              arguments = m[3].split("#{cmd} ")[1] || nil
              @ws.send("#{room}|#{self.send cmd, arguments, @room, user}")
            rescue
            end
          end

          if m[3].downcase.include? @user.downcase and user[1..-1].downcase != @user.downcase && $talk == true
            response = $cleverbot.think m[3].gsub(/#{@user}/, '').downcase!
            @ws.send("#{room}|#{user[1..-1]}, #{response}")
          end



        when  'c:'
          user = m[3].downcase
          time = m[2].to_i
          unless time < Time.now.to_i
            if m[4][0] == @symbol
              begin
                cmd = m[4].split(@symbol)[1].split(' ')[0]
                arguments = m[4].split("#{cmd} ")[1] || nil
                @ws.send("#{room}|#{self.send cmd, arguments, @room, user}")
              rescue
              end
            end
          end

        when 'updateuser'
          @rooms.each { |r| @ws.send("|/join #{r}") }

        when 'player'
          battleroom = @room[/\d+/]
          unless $battles.keys.include? @room
            $battles[battleroom.to_s] = Battle.new(@tier, true)
          end

        when 'updatechallenges'
          from = JSON.parse(m[2])
          if m[2].include? "challengecup1v1"
            puts "OK"
            @ws.send("|/accept #{from['challengesFrom'].invert['challengecup1v1']}")
            @tier = 'cc1v1'
          elsif m[2].include? 'randombattle'
            @ws.send("|/accept #{from['challengesFrom'].invert['randombattle']}")
            @tier = 'randombattle'
          elsif m[2].include? 'ou'
            @ws.send("|/useteam #{RestClient.get(TEAM_URL)}")
            @ws.send("|/accept #{from['challengesFrom'].invert['ou']}")
            @tier = 'ou'
          end
        end
      end
    end
  end
end

