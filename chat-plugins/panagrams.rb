require_relative '../plugins.rb'

require 'faraday'
class Panagram
  extend Plugin

  match_string "The scrambled Pokémon is: "

  def initialize
    @pokemon = File.read(ROOT + '/data/pokemon.txt').lines.map{|x| x.delete!("\n") }
  end

  def do(message)
    messages = message.split('|')
    scrambled_pokemon = message.split('is: <b>')[1].split('</b>')[0]
    correct_pokemon = ''
    @pokemon.each do |pokemon|
      if pokemon.chars.sort.join == scrambled_pokemon.chars.sort.join
        correct_pokemon = pokemon
      end
    end
    "/gp #{correct_pokemon}"
  end
end
