require 'byebug'
require 'faraday'

module BattleHelpers
  # Constants
  @@megaed = false

  # Effectiveness: Returns what said types (in total) are weak, immunue, and reistant against.
  def effectiveness(types, ability='none')
    weak_against = []
    resist_against = []
    immune_against = []
    types.each do |type|
      weak_against << WEAKNESSES[type]
      resist_against << RESISTANCES[type]
      immune_against << IMMUNITIES[type]
    end
    weak_against.flatten!
    resist_against.flatten!
    immune_against.flatten!
    weak_against.each do |type|
      if resist_against.include? type
        resist_against.delete(type)
        weak_against.delete(type)
      end
    end
    immune_against.each do |type|
      if weak_against.include? type
        weak_against.delete(type)
      end
    end

    if ability == 'levitate'
      weak_against.delete("ground")
    end

    if types.length <= 1 and types[0].downcase == 'normal'
      weak_against << "fighting"
    end

    unless immune_against.nil? or immune_against.empty?
      return {:weak => weak_against.uniq.map(&:to_s), :immune => immune_against.map(&:to_s), :resist => resist_against.uniq.map(&:to_s)}
    else
      return {:weak => weak_against.uniq.map(&:to_s), :immune => [], :resist => resist_against.uniq.map(&:to_s)}
    end
  end

  def decide(moves, you, opponent, tier, team)
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
    unless opponent_immunities.empty? or opponent_immunities.nil?
      opponent_immunities  = opponent_immunities.flatten.uniq
    end
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
      # Allow Sigilyph to set up.
      if you[:name].downcase == 'sigilyph'
        return "/move #{['cosmicpower', 'storedpower'].sample}"
      end
    end

    strongest = moves_power.max_by {|x| x[:power]}
    strongest = {:power => 0,:mod => 0,:name => ''}  if strongest.nil? or strongest.empty?
    switching = false
    # Check if the mod is less than 1, if opp has type adv, or pokemon fainted.
    puts "opponent type is #{opponent[:type]} and I am weak to #{effectiveness(you[:type])[:weak]}"
    if ((strongest[:mod].to_i < 1) and (tier != 'cc1v1')) or (opponent[:type] & effectiveness(you[:type], you[:ability])[:weak].map(&:to_s)).any? or you[:hp] <= 0
      switching = true
      opponent[:type].each do |type|
        team.each_with_index do |member, i|
          opponent[:type] = opponent[:type].map(&:downcase)
          if (effectiveness(opponent[:type])[:weak].map(&:to_s) & member[:type].map(&:to_s)).any?
            unless team[i][:fainted] == true
              unless team[i][:name] == you[:name]
                if member[:forced_to_switch].nil?
                  team[0], team[i] = team[i], team[0]
                  switching = false
                  puts "im switching into #{i.to_i+1} which is #{team[i]}"
                  return "/switch #{i.to_i+1}"
                end
              end
            end
          end
        end
      end
    end

    if switching == true # This means the bot couldn't find a good matchup
      switched_pokemon = team.find{|x| x[:fainted] == false}
      puts "im switching into #{switched_pokemon}"
      return "/switch #{team.index(switched_pokemon)+1}"
    end

    mega_or_not = ''

    unless tier == 'cc1v1'
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
    "/move #{strongest[:name].downcase} #{mega_or_not}"
  end
end
