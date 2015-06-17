require './commands'
require './battle'

require 'faye/websocket'
require 'cleverbot-api'
require 'rest-client'
require 'nokogiri'
require 'open-uri'
require 'json'


class ShowdownBot
  attr_accessor :team, :tier, :ladder, :p1_pkmn, :p2_pkmn, :p1_name, :p2_name

  @current_team = false
  $cleverbot = CleverBot.new
  @ws = nil
  $strongest = ''
  $moves = Array.new
  def initialize(user, pass = '', rooms, server, owner, symbol, log)
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
      event.data.gsub!(/(^>|\n)/, '')
      p event.data if @log
      event.data.split('\n').each do |m|
        @tier = 'cc1v1' if ($ladder)
        d = m
        m = m.split('|')
        case m[1]
        when 'challstr'
          url = 'http://play.pokemonshowdown.com/action.php'
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


        when 'c'
          room = m[0]
          user = m[2]
          if m[3][0] == @symbol
            begin
              cmd = m[3].split(@symbol)[1].split(' ')[0]
              arguments = m[3].split("#{cmd} ")[1] || nil
              @ws.send("#{room}|#{self.send cmd, arguments, room, user}")
            rescue
            end
          end

          if m[3].downcase.include? @user.downcase and user[1..-1].downcase != @user.downcase && $talk == true
            response = $cleverbot.think m[3].gsub(/#{@user}/, '').downcase!
            @ws.send("#{room}|#{user[1..-1]}, #{response}")
          end

        when  'c:'
          room = m[0]
          user = m[3].gsub(' ','').downcase
          if m[4][0] == @symbol
            begin
              cmd = m[4].split(@symbol)[1].split(' ')[0]
              arguments = m[4].split("#{cmd} ")[1] || nil
              @ws.send("#{room}|#{self.send cmd, arguments, room, user}")
            rescue
            end
          end

          #if m[4].downcase.include? @user.downcase and user[1..-1].downcase != @user.downcase && $talk == true
          #  response = $cleverbot.think m[4].gsub(/#{@user}/, '').downcase!
          #  @ws.send("#{room}|#{user[1..-1]}, #{response}")
          #end

        when 'updateuser'
          @rooms.each { |r| @ws.send("|/join #{r}") }

        when 'updatechallenges'
          from = JSON.parse(m[2])
          if m[2].include? "challengecup1v1"
            puts "OK"
            @ws.send("|/accept #{from['challengesFrom'].invert['challengecup1v1']}")
            @tier = 'cc1v1'
          elsif m[2].include? 'randombattle'
            @ws.send("|/accept #{from['challengesFrom'].invert['randombattle']}")
            @tier = 'randombattle'
          end

        when 'request'
          team = JSON.parse(m[2])
          if (m[2].include? 'active')
            moves = team['side']['pokemon'][0]['moves'].to_a.last(4)
            $moves.clear
            url = "http://gist.githubusercontent.com/NotBlizzard/bbebc81b2bae1f506514/raw/7de50703899d08c598e776623bdfebadd9f42ba8/moves.json"
            moves.each do |move|
              begin
                $moves << {
                  :name  => move,
                  :type  => JSON.parse(RestClient.get(url).downcase)[move.downcase.gsub('-','')]['type'].downcase,
                  :power => JSON.parse(RestClient.get(url).downcase)[move.downcase.gsub('-','')]['basepower'].downcase
                }
              rescue
              end
            end
          end

          if team.include? 'side' && @current_team == false
            (0..5).each do |x|
              @team[x] = team['side']['pokemon'][x]['ident'].gsub(/p1: /, '')
              @current_team = true
            end
          end

        when 'player'
          @battleroom = m[0].gsub(/[\n>]/, '')
          if @tier == 'cc1v1'
            @ws.send("#{@battleroom}|/team #{rand(1...7)}")
          elsif @tier == 'randombattle'
            @ws.send("#{@battleroom}|/move #{rand(1...5)}")
          end

        when 'title'
          @battleroom = m[0].gsub(/\n>/,'')
          @ws.send("#{@battleroom}|Good luck, have fun. I am a bot.")

        when '\n'
        when ''
          if m[2] == 'start'
            if @p1_name.nil?
              @p1_name = m[4].split('p1a: ')[1].downcase
              @p2_name = m[8].split('p2a: ')[1].downcase
            end
            p1_type = JSON.parse(RestClient.get("http://pokeapi.co/api/v1/pokemon/#{p1_name}"))['types']
            p2_type = JSON.parse(RestClient.get("http://pokeapi.co/api/v1/pokemon/#{p2_name}"))['types']
            @p1_pkmn = {:name => p1_name, :types => p1_type}
            @p2_pkmn = {:name => p2_name, :types => p2_type}
          end
          if d.match(/(\Wwin|\Wlose)/)
            @ws.send("#{@battleroom}|good game.")
            @ws.send("#{@battleroom}|/leave #{@battleroom}")
            if $ladder
              @ws.send("|/search challengecup1v1")
            end
          elsif d.include? 'faint'
            fainted_pokemon = message.split('faint|')[1].split('|')[0].gsub('p1a: ','').strip
            if @team.has_value? fainted_pokemon
              @team.delete(@team.invert[fainted_pokemon])
              @ws.send("#{@battleroom}|/switch #{@team.invert[@team.invert.keys.sample]}")
            end
          else
            $strongest = decide($moves, @p1_pkmn[:name].downcase, @p2_pkmn[:name].downcase)
            @ws.send("#{@battleroom}|/move #{decide($moves, @p1_pkmn[:name].downcase, @p2_pkmn[:name].downcase)}")
          end
        end
      end
    end
  end
end

