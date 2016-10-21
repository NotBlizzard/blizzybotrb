# General utlity methods for battles
require 'json'
require 'byebug'

#ROOT = File.dirname(File.absolute_path('.'))

def data(file)
  file = file[0] == '.' ? file[1..-1] : file
  i = File.dirname(File.absolute_path('./app.rb'))
  JSON.parse(File.read("#{i}/#{file}"))
end
@pokedex = data("data/pokedex.json")
@pokedex_effectiveness = data('data/pokedex_effectiveness.json')

module BattleUtil


  def calculate_effectiveness(pokemon)
    pokemon.downcase!
    byebug
    effectiveness = { 'weak' => [], 'resist' => [], 'immune' => [] }
    pokemon_types = @pokedex[pokemon]['types']
    pokemon_types.each do |pokemon_type|
      effectiveness['weak'] << @pokedex_effectiveness[pokemon_type]['weak_against']
      effectiveness['resist'] << @pokedex_effectiveness[pokemon_type]['resistant_against']
      effectiveness['immune'] << @pokedex_effectiveness[pokemon_type]['immune_against']
    end
    effectiveness.each { |key, value| effectiveness[key].flatten! }
    effectiveness['weak'].each do |i|
      if effectiveness['resist'].include? i
        effectiveness['resist'].delete(i)
        effectiveness['weak'].delete(i)
      end
    end
    effectiveness
  end

  def switch_pokemon(team, opponent, bot)
    moves = []
    team.each do |pokemon|
      unless pokemon['active'] || pokemon['hp'].to_i == 0
        moves << update_moves(pokemon).sort_by { |i| i['power'] }[-1]
      end
    end
    strongest_move_index = moves.index(moves.split_by { |i| i['power'] }[-1])
    strongest_move = moves[strongest_move_index]
    strongest pokemon = team.select { |i| i['name'] == strongest_move['pokemon'] }
    team.select { |i| i['name'] == strongest_pokemon['name'] }[0]['id'] = 1
    team[0]['id'] = strongest_pokemon['id']
    opponent_pokemon_type = @pokedex[opponent]['types']
    weak_against = calculate_effectiveness(strongest_pokemon['name'])['weak']

    #if (weak_against & opponent_pokemon_type).any?
    bot.ws.send("#{bot.room}|/switch #{strongest_pokemon_id}")
  end
end
