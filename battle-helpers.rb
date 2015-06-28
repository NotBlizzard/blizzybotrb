require 'byebug'
require 'faraday'

module BattleHelpers

  # Constants

  # Effectiveness: Returns what said types (in total) are weak, immunue, and reistant against.
  def effectiveness(types)
    weak_against = []
    resist_against = []
    immune_against = []
    types.each do |type|
      weak_against << WEAKNESSES[type]
      resistant_against << RESISTANCES[type]
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

    return {:weak => weak_against.uniq.map(&:to_s), :immune => immune_against.map(&:to_sym), :resist => resist_against.uniq.map(&:to_s)}
  end

  def decide(moves, bot, opponent)
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
    opponent_immunities  = opponent_immunities.flatten.map(&:downcase).uniq

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

      unless moves_power.length >= 4
        moves_power << {:power => move[:power] * mod, :name => move[:name], :mod => mod}
        moves_power = moves_power
      end
      # Allow Sigilyph to set up.
      if you[:name].downcase == 'sigilyph'
        return "/move #{['cosmicpower', 'storedpower'].sample}"
      end
    end

    strongest = moves_power.max_by {|x| x[:power]}
    strongest = {:power => 0,:mod => 0,:name => ''}  if strongest.nil? or strongest.empty?

    # Check if the mod is less than 1, if opp has type adv, or pokemon fainted.
    if ((strongest[:mod].to_i < 1) and (tier != 'cc1v1')) or (opp[:type] & effectiveness(you[:type])[:weak].map(&:to_s)).any? or you[:hp] <= 0
      puts 'in loop'
      opp[:type].each do |type|
        team.each_with_index do |member, i|
          opp[:type] = opp[:type].map(&:downcase)
          if ( effectiveness(opp[:type])[:weak].map(&:to_s) & member[:type].map(&:to_s) ).any?
            team[0], team[i] = team[i], team[0]
            return "/switch #{i.to_i+1}"
          end
        end
      end
    end

    "/move #{strongest[:name].downcase}"
  end
end
