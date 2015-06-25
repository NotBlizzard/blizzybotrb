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
    @opp = {}
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
      if @tier == 'cc1v1' or @tier == 'ou'
        ws.send("#{room}|/team #{rand(1...7)}")
      end
      @you[:hp] = 100
      @opp[:hp] = 100
      pkmn_team = Array.new
      if m[2].include? 'side'
        if @have_team == false
          for x in 0..5 do
            unless @tier == 'cc1v1'
              @team << {
                :nick     => data['side']['pokemon'][x]['ident'].split(': ')[1].downcase,
                :name     => data['side']['pokemon'][x]['details'].split(',')[0].gsub(/[^A-z0-9]/,'').downcase,
                :moves    => data['side']['pokemon'][x]['moves'].to_a.map(&:downcase),
                :item     => data['side']['pokemon'][x]['item'].downcase,
                :ability  => data['side']['pokemon'][x]['baseAbility'].downcase,
                :mega     => data['side']['pokemon'][x]['canMegaEvo'],
                :speed    => data['side']['pokemon'][x]['stats']['spe'],
                :fainted  => false,
                # For some reason we have to do this the hard way.
                :type     => JSON.parse(Faraday.get(POKEDEX_URL).body.downcase)[data['side']['pokemon'][x]['details'].split(',')[0].downcase.gsub(/[^A-z0-9]/,'')]['types'].map(&:downcase)
              }
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
            move = self.decide
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

          move = self.decide
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
        move = self.decide
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

  def decide(moves = @moves, you = @you, opp = @opp)
    @moves_power = []
    @strongest = ''
    opponent_weaknesses = Array.new
    opponent_resistances = Array.new
    opponent_immunities = Array.new

    opp[:type].each do |p|
      opponent_weaknesses << JSON.parse(RestClient.get(WEAKNESS_URL))[p.downcase].to_a
      opponent_resistances << JSON.parse(RestClient.get(RESISTANCE_URL))[p.downcase].to_a
      opponent_immunities << JSON.parse(RestClient.get(IMMUNITIES_URL))[p.downcase].to_a
    end

    opponent_abilities = JSON.parse(RestClient.get(POKEDEX_URL))[opp[:name].downcase]['abilities'].values.flatten.map(&:downcase)
    opponent_weaknesses = opponent_weaknesses.flatten.map(&:downcase).uniq
    opponent_resistances = opponent_resistances.flatten.map(&:downcase).uniq
    opponent_immunities = opponent_immunities.flatten.map(&:downcase).uniq

    weaknesses = 0
    resistances = 0

    moves.each_with_index do |move, i|
      mod = 1
      counts = Hash.new 0
      if @you[:type].include? move[:type]
        # STAB
        mod+=0.5
      end
      opponent_weaknesses.each {|x| counts[x] += 1}
      if counts[move[:type]] == 2
        mod+=3
      elsif counts[move[:type]] == 1
        mod+=1
      end
      counts = Hash.new 0
      opponent_resistances.each {|x| counts[x] += 1}
      if counts[move[:type]] == 2
        mod-=1.5
      elsif counts[move[:type]] == 1
        mod-=0.5
      end
      if opponent_immunities.include? move[:type]
        mod=0
      end

      unless @moves_power.length >= 4
        moves_power << {:power => move[:power] * mod, :name => move[:name], :mod => mod}
        @moves_power = moves_power
      end
      # Allow Sigilyph to set up.
      if you[:name].downcase == 'sigilyph'
        return "/move #{['cosmicpower', 'storedpower'].sample}"
      end
    end

    @strongest = @moves_power.max_by {|x| x[:power]}
    if @strongest.nil? or @strongest.empty?
      @strongest = {
        :power => 0,
        :mod => 0,
        :name => ''
      }
    end

    pkmn_counter = Array.new(6) { |x| x = 0 }
    @opp_super_eff_against = []
    opp[:type].each do |type|
      @opp_super_eff_against << JSON.parse(Faraday.get(SUPER_EFFECTIVENESS_URL).body.downcase)[type.downcase].to_a
    end
    @opp_super_eff_against.flatten!

    puts "I AM #{you[:type]}"
    puts "OP IS #{opp[:type]} and I AM WEAK AGAINST #{effectiveness(you[:type])[:weak].map(&:to_s)}"
    # Check if the mod is less than 1, if opp has type adv, or pokemon fainted.
    if ((@strongest[:mod].to_i < 1) and (@tier != 'cc1v1')) or (opp[:type] & effectiveness(you[:type])[:weak].map(&:to_s)).any? or you[:hp] <= 0
      puts 'in loop'
      opp[:type].each do |type|
        @team.each_with_index do |member, i|
          opp[:type] = opp[:type].map(&:downcase)
          if ( effectiveness(opp[:type])[:weak].map(&:to_s) & member[:type].map(&:to_s) ).any?
            switch = @t[i]
            in_pkmn = 0
            #@team[in_pkmn], @team[i] = @team[i], @team[in_pkmn]
            return "/switch #{i.to_i+1}"
          end
        end
      end
    end

   # if ['choicescarf','choiceband','choicespecs'].include? you[:item].gsub(' ','') and @choice_move.empty?
   #   @choice_move = @strongest[:name].downcase
   # end

    unless @choice_move.empty?
      return "/move #{@choice_move.to_i+1}"
    end

    return "/move #{@strongest[:name].downcase}"
  end
  def effectiveness(types)
    weak_against = []
    resistant_against = []
    immune_against = []
    types.each do |type|
      weak_against << JSON.parse(Faraday.get(WEAKNESS_URL).body.downcase)[type]
      resistant_against << JSON.parse(Faraday.get(RESISTANCE_URL).body.downcase)[type]
      immune_against << JSON.parse(Faraday.get(IMMUNITIES_URL).body.downcase)[type]

    end
    weak_against.flatten!
    resistant_against.flatten!
    immune_against.flatten!
    weak_against.each do |type|
      if resistant_against.include? type
        resistant_against.delete(type)
        weak_against.delete(type)
      end
    end
    immune_against.each do |type|
      if weak_against.include? type
        weak_against.delete(type)
      end
    end

    return {:weak => weak_against.uniq.map(&:to_s), :immune => immune_against.map(&:to_sym), :resist => resistant_against.uniq.map(&:to_s)}
  end
end