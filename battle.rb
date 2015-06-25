require 'json'
require 'rest-client'
require 'byebug'
MOVES_URL = "https://gist.githubusercontent.com/NotBlizzard/bbebc81b2bae1f506514/raw/7de50703899d08c598e776623bdfebadd9f42ba8/moves.json"
WEAKNESS_URL = "https://gist.githubusercontent.com/NotBlizzard/f2e72ad079b6a211c2b0/raw/a734064c23cea6027f9c720afdc6376c8e6ee9e5/weaknesses.json"
POKEDEX_URL = "https://gist.githubusercontent.com/NotBlizzard/a84ad1737c801f748b01/raw/69dc8756a924aa846a4673c591ebf37a0fc60980/pokedex.json"
SUPER_EFFECTIVENESS_URL = "https://gist.githubusercontent.com/NotBlizzard/dede16ec50b4d4693b2d/raw/1e117b0ffb98ba0fa47d6b5f0da9d52a537266ae/supereffectiveness.json"
RESISTANCE_URL = "https://gist.githubusercontent.com/NotBlizzard/cc46e43ac6df8e87e1f9/raw/84e8164a2a92bed7ca81fc7df503209975a1fef6/resistances.json"
IMMUNITIES_URL = "https://gist.githubusercontent.com/NotBlizzard/ae9017358a93d49ad25f/raw/64a3961aaa8b0697c815b340eec164eec7e0e4e2/immunities.json"

class Battle
  attr_accessor :ws, :room, :moves_power, :you, :team, :opp, :strongest, :magaed

  def initialize(tier, challenged)
    ws = ws
    @t = []
    @tier = tier
    @team = []
    @moves = []
    @you = {}
    @opponent = {}
    @moves_power = []
    @p1 = true
    @have_team = false
    @choice_move = ''
    @challenged = challenged
    @greeted = false
  end

  def run(ws, data, room)
    if @challenged
      @p1 = true
    else
      @p1 = false
    end
    d = data
    m = data.split('|')
    puts "m1 is #{m[1]}"
    case m[1]
    when 'request'
      data = JSON.parse(m[2])
      if m[2].split(':')[0].include? "active"
        data['active'][0]['moves'].each_with_index do |_, i|
            @moves << {
              :name     => data['active'][0]['moves'][i]['id'],
              :type     => JSON.parse(Faraday.get(MOVES_URL).body.downcase)[data['active'][0]['moves'][i]['id'].downcase.gsub('-','')]['type'].downcase,
              :power    => JSON.parse(Faraday.get(MOVES_URL).body.downcase)[data['active'][0]['moves'][i]['id'].downcase.gsub('-','')]['basepower'],
              :priority => JSON.parse(Faraday.get(MOVES_URL).body.downcase)[data['active'][0]['moves'][i]['id'].downcase.gsub('-','')]['priority']
            }
        end
      end
      if @greeted == false
        ws.send("#{room}|glhf")
        @greeted = true
      end
      ws.send("#{room}|/team #{rand(1...7)}")if @tier == 'cc1v1' or @tier == 'ou'

      pkmn_team = Array.new
      if m[2].include? 'side'
        if @have_team == false
          @team = get_team(m[2])
            else
              @you[:item] = data['side']['pokemon'][0]['item']
              @you[:moves] = data['side']['pokemon'][0]['moves']
              @you[:mega] = data['side']['pokemon'][0]['canMegaEvo']
              @you[:name] = data['side']['pokemon'][0]['details'].split(',')[0].gsub(/[^A-z0-9]/,'')
              @you[:type] = JSON.parse(Faraday.get(POKEDEX_URL).body.downcase)[@you[:name].downcase]["types"]
            end
          end
        end
      end
      puts @team
      byebug
      @have_team = true
      puts "TEAM IS NOW #{@team}"

    when 'win'
    when 'lose'
    when 'tie'
      ws.send("#{room}|good game")
      ws.send("#{room}|/part")

    when 'faint'
      if @tier == 'cc1v1'
        ws.send("#{room}|good game")
        ws.send("#{room}|/part")
      else
        pkmn = m[2].split(': ')[1]
        if @p1
          if m[2].include? "p1a: "
            @t.find{|x| x[:nick] == pkmn}[:fainted] = true
            @you[:hp] = 0
            @moves_power = []
            move = decide(@moves, @you, @opponent)
            ws.send("#{room}|#{move}")
          end
        end
      end

    when 'player'
      if @p1
        if (d.include? "p2a: ")

          @you[:name] = d.split("#{@me}a: ")[1].split('|')[0].downcase.gsub(/[^A-z0-9]/, '')
          @opp[:name] = d.split("#{@op}a: ")[1].split('|')[0].downcase.gsub(/[^A-z0-9]/, '')

          @you[:item] = @team.find{|x| x[:name] == @you[:name]}[:item]

          @you[:type] = JSON.parse(RestClient.get(POKEDEX_URL))[@you[:name]]['types'].map(&:downcase)
          @opp[:type] = JSON.parse(RestClient.get(POKEDEX_URL))[@opp[:name]]['types'].map(&:downcase)

          @you[:speed] = JSON.parse(Faraday.get(POKEDEX_URL).body)[@you[:name]]['baseStats']['spe']
          @opp[:speed] = JSON.parse(Faraday.get(POKEDEX_URL).body)[@opp[:name]]['baseStats']['spe']

          move = decide(@moves, @you, @opponent)
          ws.send("#{room}|#{move}")
        end
      end

    when '-damage'
      if @p1
        if m[2].include? "p1a"
          if m[3].include? 'fnt'
            @you[:hp] = 0
          else
            @you[:hp] = Rational(m[3].split('/')[0]) / m[3].split('/')[1].to_f
            if m[3].include? " "
              @you[:hp] = Rational(m[3].split('/')[0]) / m[3].split('/')[1].split(' ')[0].to_f
            end
          end
        end
      else
        if m[3].include? 'fnt'
          @opp[:hp] = 0
        else
          @opp[:hp] = Rational(m[3].split('/')[0]) / m[3].to_f
          if m[3].include? " "
            @opp[:hp] = Rational(m[3].split('/')[0]) / m[3].split('/')[1].split(' ')[0].to_f
          end
        end
      end

      when 'turn'
        move = decide(@moves, @you, @opponent)
        unless @tier == 'cc1v1'
          byebug
          if @team.find{|x| x[:name].downcase == @you[:name]}[:mega] == true
            if @megaed == false
              ws.send("#{room}|#{move} mega")
              @magaed = true
            end
          else
            ws.send("#{room}|#{move}")
          end
        else
          if @you[:mega] == true
            ws.send("#{room}|#{move} mega")
          else
            ws.send("#{room}|#{move}")
          end
        end
        ws.send("#{room}|#{move}")

    when 'switch'
      if @p1
        if m[2].include? 'p1a'
          unless @tier == 'cc1v1'
            @you[:name] = m[3].split(',')[0].downcase.gsub(/[^A-z0-9]/,'')
            @you[:type] = JSON.parse(RestClient.get(POKEDEX_URL))[@you[:name]]['types'].map(&:downcase)
            puts "team is #{@team}"#.find{|x| x[:name] == @you[:name]}[:item]
            @you[:speed] = JSON.parse(Faraday.get(POKEDEX_URL).body.downcase)[@you[:name]]['basestats']['spe']
          end
        else
          @opp[:name] = m[3].split(',')[0].downcase.gsub(/[^A-z0-9]/,'')
          puts "ok, team is #{@team}"
          @opp[:type] = JSON.parse(Faraday.get(POKEDEX_URL).body.downcase)[@opp[:name]]['types']
          @opp[:speed] = JSON.parse(Faraday.get(POKEDEX_URL).body.downcase)[@opp[:name]]['basestats']['spe']
        end
      end
    end
  end
end