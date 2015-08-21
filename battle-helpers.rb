require 'byebug'
require 'faraday'

module BattleHelpers
  @@megaed = false
  @@choiced_move = {}

  def effectiveness(types, ability='none')
    effectiveness = {:weak => [], :resist => [], :immune => []}
    types.each do |type|
      effectiveness[:weak] << WEAKNESSES[type]
      effectiveness[:resist] << RESISTANCES[type]
      effectiveness[:immune] << IMMUNITIES[type]
    end
    effectiveness.values.each(&:flatten!)

    effectiveness[:weak].each do |type|
      if effectiveness[:resist].include? type
        effectiveness[:resist].delete(type)
        effectiveness[:weak].delete(type)
      end
    end
    effectiveness[:immune].each do |type|
      if effectiveness[:weak].include? type
        effectiveness[:weak].delete(type)
      end
    end

    if ability == 'levitate'
      effectiveness[:weak].delete("ground")
    end

    if types.length <= 1 and types[0].downcase == 'normal'
      effectiveness[:weak] << "fighting"
    end

    {:weak => effectiveness[:weak].uniq.map(&:to_s), :immune => effectiveness[:immune].map(&:to_s), :resist => effectiveness[:resist].uniq.map(&:to_s)}
  end

  def opponent_effectiveness(opponent)
    opponent[:type].map{|x| x.downcase! }
    moves_power = []
    strongest = ''
    opponent_weaknesses  = []
    opponent_resistances = []
    opponent_immunities  = []
    opponent[:type].each do |p|
      opponent_weaknesses  << WEAKNESSES[p.downcase]
      opponent_resistances << RESISTANCES[p.downcase]
      opponent_immunities  << IMMUNITIES[p.downcase]
    end

    opponent_abilities   = POKEDEX[opponent[:name].downcase]['abilities'].values.flatten.map(&:downcase)
    opponent_weaknesses  = opponent_weaknesses.flatten.map(&:downcase).uniq
    opponent_resistances = opponent_resistances.flatten.map(&:downcase).uniq
    return opponent_immunities, opponent_weaknesses, opponent_resistances
  end

  def get_moves_power(moves, you, opponent_weaknesses, opponent_resistances, opponent_immunities)
    moves_power = []
    moves.each do |move|
      mod = 1
      counts = Hash.new 0
      if you[:type].include? move[:type]
        mod += 0.5
      end
      opponent_weaknesses.each {|x| counts[x] += 1}
      if counts[move[:type]] == 2
        mod += 3
      elsif counts[move[:type]] == 1
        mod += 1
      end
      counts = Hash.new 0
      opponent_resistances.each {|x| counts[x] += 1}
      if counts[move[:type]] == 2
        mod -= 1.5
      elsif counts[move[:type]] == 1
        mod -= 0.5
      end
      if opponent_immunities.include? move[:type]
        mod = 0
      end

      moves_power << {:power => move[:power] * mod, :name => move[:name], :mod => mod}
    end
    moves_power
  end

  def to_mega_or_not(tier, team, you)
    mega_or_not = ''
    unless tier == 'challengecup1v1'
      unless team.find{|x| x[:name].downcase == you[:name].downcase}.nil?
        if @@megaed == false and team.find{|x| x[:name].downcase == you[:name].downcase}[:mega] == true
          mega_or_not = 'mega'
          @@megaed = true
        end
      end
    else
      if you[:mega] == true
        mega_or_not = 'mega'
      end
    end
    mega_or_not
  end

  def no_good_switch(team)
    switched_pokemon = team.find{|x| x[:fainted] == false}
    unless switched_pokemon.nil?
      unless switched_pokemon[:name] == you[:name]
        puts "i'm switching into #{switched_pokemon} which is /switch #{team.index(switched_pokemon)+1}"
        i = team.index(switched_pokemon)
        team[0], team[i] = team[i], team[0]
        return "/switch #{i+1}"
      end
    end
  end

  def get_switch(team, opponent, you)
    team.each do |member|
      opponent[:type] = opponent[:type].map(&:downcase)
      if (effectiveness(opponent[:type])[:weak].map(&:to_s) & member[:type].map(&:to_s)).any? and member[:fainted] == false
        unless member[:name] == you[:name]
          if member[:forced_to_switch].nil?
            switching = false
            i = team.index(member)
            puts "im switching into #{member} which is /switch #{i+1}"
            team[0], team[i] = team[i], team[0]
            return "/switch #{i+1}"
          end
        end
      end
    end
  end

  def decide(moves, you, opponent, tier, team, skip_switch = false)

    opponent_immunities, opponent_weaknesses, opponent_resistances = opponent_effectiveness(opponent)

    moves_power = get_moves_power(moves, you, opponent_weaknesses, opponent_resistances, opponent_immunities)

    strongest = moves_power.max_by {|x| x[:power]}
    strongest = {:power => 0,:mod => 0,:name => ''}  if strongest.nil? or strongest.empty?
    switching = false
    # Check if the mod is less than 1, if opp has type adv, or pokemon fainted.
    unless skip_switch == true
      if ((strongest[:mod].to_i < 1) and (tier != 'challengecup1v1')) or (opponent[:type] & effectiveness(you[:type], you[:ability])[:weak].map(&:to_s)).any? or you[:hp] == 0 or (you[:forced_switch] == true)
        unless tier == 'challengecup1v1'
          switching = true
          return get_switch(team, opponent, you)
        end
      end
    end

    if switching == true # This means the bot couldn't find a good matchup
      puts "I couldnt find a good switch"
      return no_good_switch(team)
    end

    mega_or_not = to_mega_or_not(tier, team, you)

    if ['choiceband','choicescarf','choicespecs'].include? you[:item] and @@choiced_move[you[:name]].nil?
      @@choiced_move[you[:name]] = strongest[:name].downcase
    end

    return "/move #{@@choiced_move[you[:name]]}" if ['choiceband','choicescarf','choicespecs'].include? you[:item]

    "/move #{strongest[:name].downcase} #{mega_or_not}"
  end
end
