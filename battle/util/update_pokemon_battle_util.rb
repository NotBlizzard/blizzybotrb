require 'json'

def data(file)
  file = file[0] == '.' ? file[1..-1] : file
  i = File.dirname(File.absolute_path('./app.rb'))
  JSON.parse(File.read("#{i}/#{file}"))
end

# Battle utility methods to update Pokemon.
module UpdatePokemonBattleUtil
  @moves = data('data/pokedex_moves.json')

  def update_pokemon_move(pokemon, move)
    if move.include? 'hiddenpower'
      move = {
        'name' => move[0..-3],
        'power' => 60,
        'type' => move[/\D+/][11..-1]
      }
    else
      #puts "MOVE IS "
      #puts move
      #byebug
      move = {
        'name' => move,
        'power' => @moves[move]['power'],
        'type' => @moves[move]['type']
      }
    end
    move['power'] = 102 if move['name'] == 'return'
    if %w(eruption waterspout).include? move['name']
      move['power'] = 150 * pokemon['hp']
    end
    move
  end

  def update_pokemon(data, i)
    {
      'id' => i + 1,
      'name' => data['ident'].split(': ')[1].delete('-'),
      'moves' => data['moves'],
      'stats' => data['stats'],
      'active' => data['active'],
      'hp' => data['condition'],
      'ability' => data['baseAbility']
    }
  end

  def update_team(data)
    data = JSON.parse(data)['side']['pokemon']
    team = []
    data.each_with_index { |pokemon, i| team << update_pokemon(pokemon, i) }
    team
  end

  def update_move_power(pokemon, move)
    move = update_pokemon_move(pokemon, move)
    puts "MOVE IS NOW"
    puts move
    if @moves[move['name']].key? 'multihit'
      move['power'] *= @moves[move['name']]['multihit'][0]
    end
    move
  end

  def update_moves(pokemon = nil)
    moves = []
    pokemon['moves'].each { |move| moves << update_move_power(pokemon, move) }
    #byebug
    moves.each do |move|
      modifier = pokemon_move_modifier(pokemon, move)
      pokedex_moves << {
        'name' => move['name'],
        'power' => move['power'] * modifier,
        'pokemon' => pokemon['name']
      }
    end
    pokedex_moves
  end
end
