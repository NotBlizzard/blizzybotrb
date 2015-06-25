require 'json'
require 'yaml'

$ranks = JSON.parse(File.read('ranks.json'))
$owner = YAML.load_file('options.yaml')['owner']

class Array
  def englishize
    if self.length == 2
      return self.join(' and ')
    else
      last_element = self.last
      new_arr = self - Array(last_element)
      str = new_arr.join(', ')
      return "#{str}, and #{last_element}"
    end
  end
end

class String

  def flip
    self.downcase.tr!('a-z','ɐqɔpǝɟƃɥᴉɾʞlɯuodbɹsʇnʌʍxʎz').reverse
  end

  def can(cmd)
    return true if self =~ /(?<=^.)#{$owner}/i
    groups = {
        'u' => 0,
        '+' => 1,
        '%' => 2,
        '@' => 3,
        '#' => 4,
        '&' => 4,
        '~' => 5,
        'off' => 6
    }
    r = self[0]
    r = 'u' if r == ' '
    return groups[r] >= groups[$ranks[cmd]]
  end
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

def get_team(data)
  data = JSON.parse(data)
  for x in 0..5 do
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
  end
end

def decide(moves, you, opp)
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

  unless @choice_move.empty?
    return "/move #{@choice_move.to_i+1}"
  end

  return "/move #{@strongest[:name].downcase}"
end