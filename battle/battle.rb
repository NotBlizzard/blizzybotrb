# battle.rb - Where the battles happen.

require 'json'

require './battle/util/battle_util.rb'
require './battle/util/modifier_battle_util.rb'
require './battle/util/update_pokemon_battle_util.rb'

def data(file)
  JSON.parse(File.read(file))
end

# Battles on Pokemon Showdown
class Battle
  attr_accessor :id, :tier, :room, :team, :opponent, :weather, :active,
                :pokedex, :pokedex_moves, :pokedex_effectiveness, :bot

  include UpdatePokemonBattleUtil
  include ModifierBattleUtil
  include BattleUtil

  def initialize(ws, tier, room, bot)
    @ws = ws
    @bot = bot
    @active = nil
    @id = nil
    @tier = tier
    @room = room
    @team = team
    @opponent = nil
    @weather = nil
    @pokedex = data('./data/pokedex.json')
    @moves = data('./data/pokedex_moves.json')
    @pokedex_effectiveness = data('./data/pokedex_effectiveness.json')
  end

  def to_s
    "<Battle: room:#{@room}>"
  end

  def start(_)
    @ws.send("#{@room}|Good Luck, Have Fun.")
    decide(_)
  end

  def battle(messages)
    messages.map(&:downcase)
    case messages[1]
    when 'player'
      @id = player(messages)
    else
      begin
        send(messages[1], messages)
      rescue
      end
    end
  end

  def turn(_)
    decide
  end

  def win_lose_tie(_)
    @ws.send("#{@room}|Good Game.")
    @ws.send("#{@room}|/part")
  end

  def weather(messages)
    if messages.length > 4
      pokemon = messages[4].split(': ')[1].downcase
      @weather = messages[2].downcase
      case @weather
      when 'sandstorm'
        @ws.send("#{@room}|I guess #{pokemon} must be Darude.")
      when 'hail'
        @ws.send("#{@room}|The ~~cold~~ hail never bothered me anyway.")
      end
    end
  end

  def player(message)
    id = nil
    if @bot.user == message[3]
      id = message[2]
    else
      id = message[2] == 'p1' ? 'p2' : 'p1'
    end
    id
  end

  def request(message)
    @team = update_team(message[2])
    @id = JSON.parse(message[2])['side']['id']
  end

  def faint(message)
    if message.include? @id
      pokemon = message.split(': ')[1].downcase
      unless @team.select { |i| i['name'] == pokemon }.empty?
        switch_pokemon(@team, @opponent, self)
      end
    end
  end

  def switch(message)
    i = @id == 'p1' ? 'p2a' : 'p1a'
    if message[2].include? i
      opponent = message[3].delete('-').split(',')[0].downcase
      if opponent != @opponent
        @opponent = opponent
        @do_not_switch = false
      end
    end
  end

  def teampreview(_)
    @ws.send("#{@room}|/team #{rand(1..6)}|1")
  end

  def decide(_)
    @active = @team.select { |i| i['active'] }[0]
    opponent_pkmn_type = @pokedex[@opponent]['types']
    weak_against = calculate_effectiveness(@active['name'])['weak']
    if (weak_against & opponent_pkmn_type).any?
      return switch_pokemon(@team, @opponent, self)
    end

    if @active['hp'] == '0 fnt'
      @do_not_switch = false
      return switch_pokemon(@team, @opponent, self)
    end
    @strongest_move = update_moves(@active).sort_by { |i| i['power'] }[-1]

    return switch_pokemon if @strongest_move['power'] == 0

    @ws.send("#{@room}|/move #{@strongest_move['name']}")
  end
end
