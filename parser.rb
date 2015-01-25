require './commands.rb'

require 'faye/websocket'
require 'cleverbot-api'
require 'rest_client'
require 'nokogiri'
require 'open-uri'
require 'yaml'
require 'json'


class ShowdownBot
  include Commands
  $current_team = false
  $battleroom = nil
  $messages = Hash.new
  $team = Hash.new
  $tier = nil
  $bot = CleverBot.new
  def initialize(user, pass = nil, rooms, server, owner, symbol, log)
    @user = user
    @pass = pass
    @rooms = rooms
    @server = server
    @owner = owner
    @symbol = symbol
    @log = log
  end

  def self.messages
    $messages
  end

  def run
    ws = Faye::WebSocket::Client.new("ws://#{@server}/showdown/websocket")

    ws.on :message do |event|
      p [:message, event.data] if @log
      event.data.split('\n').each do |m|
        m = m.gsub(/[\n>]/,'').split('|')
       
        case m[1]
        when 'challstr'
          url = "http://play.pokemonshowdown.com/action.php"
          if @pass.nil? or @pass == ''
            url_data = "?act=getassertion&userid=#{@user}&challengekeyid=#{m[2]}&challenge=#{m[3]}"
            data = RestClient.get url+url_data
            ws.send("|/trn #{@user}, 0, #{data}")         
          else
            data = RestClient.post url, :act => 'login', :name => @user, :pass => @pass, :challengekeyid => m[2], :challenge => m[3]
            data = JSON.parse(data.split(']')[1])
            ws.send("|/trn #{@user},0,#{data['assertion']}")
          end

        when 'updatechallenges'
          from = JSON.parse(m[2])
          if from.include? 'challengecup1vs1'
            ws.send("|/accept #{from['challengesFrom'].invert['challengecup1vs1']}")
            @tier = 'cc1v1'
          elsif from.include? 'randombattle'
            ws.send("|/accept #{from['challengesFrom'].invert['randombattle']}")
            @tier = 'randombattle'
          end

        when  'c:'
          room = m[0]
          user = m[3]
          if m[4][0] == @symbol
            cmd = m[4].split(@symbol)[1].split(' ')[0]
            arguments = m[4].split("#{cmd} ")[1] || nil

            ws.send("#{room}|#{send cmd, arguments, user}") 

          end

          $messages[user[1..-1]] = [m[2],[m[4]]]
          if m[4].include? @user and m[4][0] != @symbol
            ws.send("#{room}|#{$bot.think m[4].gsub(/#{@user}/,'')}")
          end

        when 'updateuser'
          @rooms.each { |r| ws.send("|/join #{r}") }

        when 'tournament'
          begin
            data = JSON.parse(m[3])
            if !data['challenges'].nil?
              ws.send("#{room}|/tour challenge #{['challenges']}")
            end
          rescue
          end

        when 'request'
          team = JSON.parse(m[2])
          if team.include? 'side' && $current_team == false
            (0..5).each do |x|
              $team[x] = team['side']['pokemon'][x]['ident'].gsub(/p1: /,'')
              $current_team = true
            end
          end

        when 'player'
          $battleroom = m[0].gsub(/[\n>]/,'')
          if @tier == 'cc1v1'
            ws.send("#{$battleroom}|/team #{rand(1...7)}")
          elsif @tier == 'r&&ombattle'
            ws.send("#{$battleroom}|/move #{rand(1...5)}")
          end

        when 'title'
          $battleroom = msg[0].gsub(/\n>/,'')
          ws.send("#{$battleroom}|Good luck, have fun.")

        when '\n'
          if m.match(/(\Wwin|\Wlose)/)
            ws.send("#{$battleroom}|good game.")
            ws.send("#{$battleroom}|/leave #{$battleroom}")
          elsif m.include? 'faint'
            fainted_pokemon = message.split('faint|')[1].split('|')[0].gsub('p1a: ','').strip
            if $team.has_value? fainted_pokemon
              $team.delete($team.invert[fainted_pokemon])
              ws.send("#{$battleroom}|/switch #{$team.invert[$team.invert.keys.sample]}")
            end
          else
            ws.send("#{$battleroom}|/move #{rand(1...5)}")
          end
        end
      end
    end
  end
end
