require './commands'

require 'faye/websocket'
require 'cleverbot-api'
require 'rest_client'
require 'nokogiri'
require 'open-uri'
require 'json'


class ShowdownBot
  attr_accessor :owner

  @current_team = false
  @battleroom = nil
  @team = {}
  @tier = nil
  $cleverbot = CleverBot.new
  def initialize(user, pass = '', rooms, server, owner, symbol, log)
    @server = server
    @symbol = symbol
    @owner = owner
    @rooms = rooms
    @pass = pass
    @user = user
    @log = log
  end

  def self.exit
    @ws.close
  end

  def run
    @ws = Faye::WebSocket::Client.new("ws://#{@server}/showdown/websocket")

    @ws.on :message do |event|
      event.data.gsub!(/(^>|\n)/,'')
      p event.data if @log
      event.data.split('\n').each do |m|
        m = m.split('|')
        case m[1]
        when 'challstr'
          url = "http://play.pokemonshowdown.com/action.php"
          if @pass.nil?
            data = RestClient.get url, :params => {:act => 'getassertion', :userid => @user, :challengekeyid => m[2], :challenge => m[3]}
            @ws.send("|/trn #{@user},0,#{data}")
          else
            data = RestClient.post url, :act => 'login', :name => @user, :pass => @pass, :challengekeyid => m[2], :challenge => m[3]
            data = JSON.parse(data.split(']')[1])
            @ws.send("|/trn #{@user},0,#{data['assertion']}")
          end

        when 'pm'
          user = m[2]
          if m[4].downcase.include? @user.downcase
            @ws.send("|/pm #{user}, #{$cleverbot.think m[4]}")
          end

        when  'c:'
          room = m[0]
          user = m[3]
          user_without_rank = user[1..-1]
          if m[4][0] == @symbol
            begin
              cmd = m[4].split(@symbol)[1].split(' ')[0]
              arguments = m[4].split("#{cmd} ")[1] || nil
              @ws.send("#{room}|#{send cmd, arguments, user}")
            rescue
            end
          end

          if m[4].downcase.include? @user.downcase and m[4][0] != @symbol and user_without_rank != @user.downcase
            response = $cleverbot.think m[4].gsub(/#{@user}/,'').downcase!
            @ws.send("#{room}|#{user_without_rank}, #{response}")
          end

        when 'updateuser'
          @rooms.each { |r| @ws.send("|/join #{r}") }

        when 'updatechallenges'
          from = JSON.parse(m[2])
          if from.include? 'challengecup1vs1'
            @ws.send("|/accept #{from['challengesFrom'].invert['challengecup1vs1']}")
            @tier = 'cc1v1'
          elsif from.include? 'randombattle'
            @ws.send("|/accept #{from['challengesFrom'].invert['randombattle']}")
            @tier = 'randombattle'
          end

        when 'request'
          team = JSON.parse(m[2])
          if team.include? 'side' && @current_team == false
            (0..5).each do |x|
              @team[x] = team['side']['pokemon'][x]['ident'].gsub(/p1: /,'')
              @current_team = true
            end
          end

        when 'player'
          @battleroom = m[0].gsub(/[\n>]/,'')
          if @tier == 'cc1v1'
            @ws.send("#{@battleroom}|/team #{rand(1...7)}")
          elsif @tier == 'randombattle'
            @ws.send("#{@battleroom}|/move #{rand(1...5)}")
          end

        when 'title'
          @battleroom = m[0].gsub(/\n>/,'')
          @ws.send("#{@battleroom}|Good luck, have fun.")

        when '\n'
          if m.match(/(\Wwin|\Wlose)/)
            @ws.send("#{@battleroom}|good game.")
            @ws.send("#{@battleroom}|/leave #{@battleroom}")
          elsif m.include? 'faint'
            fainted_pokemon = message.split('faint|')[1].split('|')[0].gsub('p1a: ','').strip
            if @team.has_value? fainted_pokemon
              @team.delete(@team.invert[fainted_pokemon])
              @ws.send("#{@battleroom}|/switch #{@team.invert[@team.invert.keys.sample]}")
            end
          else
            @ws.send("#{@battleroom}|/move #{rand(1...5)}")
          end
        end
      end
    end
  end
end
