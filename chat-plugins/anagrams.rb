require_relative '../plugins.rb'

class Anagram
  extend Plugin

  match_string /\[Pokemon\]/

  def initialize
    @pokemon = File.read(ROOT + '/data/pokemon.txt').lines.map{|x| x.delete!("\n") }
  end

  def do(message)
    scrambled_pokemon = message.split('[Pokemon] ')[1].gsub(' ','').gsub(',','')
    correct_pokemon = ''
    @pokemon.each do |pokemon|
      if pokemon.chars.sort.join == scrambled_pokemon.chars.sort.join
        correct_pokemon = pokemon
      end
    end
    "+guess #{correct_pokemon}"
  end
end
