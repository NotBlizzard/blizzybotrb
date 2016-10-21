# Battle utlity methods to update modifier.
module ModifierBattleUtil
  def calculate_weak(effectiveness, pokemon_move_type, modifier)
    if effectiveness['weak'].count(pokemon_move_type) == 2
      modifier *= 4
    elsif effectiveness['weak'].count(pokemon_move_type) == 1
      modifier *= 2
    end
    modifier
  end

  def calculate_resist(effectiveness, pokemon_move_type, modifier)
    if effectiveness['resist'].count(pokemon_move_type) == 2
      modifier *= 0.25
    elsif effectiveness['resist'].count(pokemon_move_type) == 1
      modifier *= 0.5
    end
    modifier
  end

  def calculate_immune(effectiveness, pokemon_move_type, modifier)
    return modifier if effectiveness['immune'].empty?
    if effectiveness['immune'].include? pokemon_move_type
      return 0 unless pokemon['ability'] == 'scrappy'
      return modifier if %w(fighting normal).include? pokemon_move_type
    end
  end

  def calculate_effectiveness_modifier(pokemon, pokemon_move_type, modifier)
    effectiveness = calculate_effectiveness(pokemon['name'])
    modifier = calculate_weak(effectiveness, pokemon_move_type, modifier)
    modifier = calculate_resist(effectiveness, pokemon_move_type, modifier)
    modifier = calculate_immune(effectiveness, pokemon_move_type, modifier)
  end

  def calculate_effectiveness_ability(pokemon_move_type)
    opponent = @pokedex[@opponent]['abilities']
    {
      'water' => 'waterabsorb',
      'grass' => 'sapsipper',
      'fire' => 'flashfire',
      'electric' => 'voltabsorb',
      'ground' => 'levitate'
    }.each do |key, value|
      return 0 if (pokemon_move_type == key) && (@opponent.include? value)
    end
  end

  def pokemon_move_modifier(pokemon, move)
    byebug
    pokemon['type'] = @pokedex[pokemon['name']]['types']
    modifier = 1
    if pokemon['type'].include? move['type']
      modifier = pokemon['ability'] == 'adaptability' ? 2 : 1.5
    end
    modifier = calculate_effectiveness_modifier(pokemon, move['type'], modifier)
    modifier = calculate_effectiveness_ability(move['type'])
    modifier
  end

  def pokemon_ability_move_power_fire_water_grass(ability, pokemon, move)
    i = {
      'blaze' => 'fire',
      'overgrow' => 'grass',
      'torrent' => 'water',
      'swarm' => 'bug'
    }
    if (i.keys.include? ability) && pokemon['hp'] <= 0.3
      move['power'] *= 1.5 if i[ability] == move['type']
      return move
    end
  end

  def pokemon_ability_move_power_fairy_dark(ability, move)
    { 'darkaura' => 'dark', 'fairyaura' => 'fairy' }.each do |key, value|
      return move['power'] *= 1.33 if ability == key && move['type'] == value
    end
  end

  def pokemon_ability_move_power_(ability, move)
    {
      'ironfist' => ['punch_move', 1.2],
      'megalauncher' => ['pulse_move', 1.5],
      'reckless' => ['recoil', 1.2],
      'sheerforce' => ['secondary_effect', 1.3],
      'strongjaw' => ['bite_move', 1.5],
      'toughclaws' => ['contact_move', 1.3]
    }.each do |key, value|
      next unless ability == key
      if @pokedex_move[move['name']].values.include? value[0]
        move['power'] *= value[1]
      end
    end
    move
  end

  def pokmeon_ability_move_power_sandforce(ability, move)
    move['power'] *= 1.3 if ability == 'sandforce'
    move
  end

  def pokemon_ability_move_power_technician(ability, move)
    move['power'] *= 1.5 if ability == 'technician' && move['power'] <= 60
    move
  end

  def pokemon_ability_move_power(pokemon, move)
    ability = pokemon['ability']
    move['type'] = 'flying' if ability == 'aerilate' && move['type'] == 'normal'

    move = pokemon_ability_move_power_fire_water_grass(ability, pokemon, move)
    move = pokemon_ability_move_power_fairy_dark(ability, pokemon, move)
    move = pokemon_ability_move_power_(ability, pokemon, move)
    move = pokmeon_ability_move_power_sandforce(ability, move)
    move = pokemon_ability_move_power_technician(ability, move)
    move['power']
  end
end
