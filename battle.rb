require 'json'
require 'byebug'
require './helpers.rb'
require './battle-helpers.rb'
require './battle-parser.rb'


class Battle
  attr_accessor :team, :moves, :bot, :opponent, :tier
  include BattleHelpers

  def initialize(tier, player_one)
    @tier = tier
    @team = []
    @moves = []
    @bot = {}
    @opponent = {}
    @player_one =player_one
    @have_team = false
  end

  def run(ws, data, room)
    handler = BattleHandler.new(@ws, @bot, @opponent, data)
    @player_one = @challenged

    message = data.split('|')
    case message[1].downcase
    when 'request'
      @moves = BattleHandler.get_moves if message[2].split(':')[0].include? "active"
      unless @have_team
        @team = BattleHandler.get_team(message[2])
        @have_team = true
      end
      BattleHandler.request(@bot, @team, @have_team, room, @tier)

    when 'win','lose','tie'
      BattleHandler.win_lose_tie(room)

    when 'faint'
      BattleHandler.faint(room, @team)

    when 'player'
      BattleHandler.player(@bot, @opponent, data, @player_one, ws, @moves)

    when '-damage'
      BattleHandler.damage

    when 'turn'
      move = BattleHelpers.decide(@moves, @bot, @opponent)
      BattleHandler.mega_or_not(@team, @bot, ws)

    when 'switch'
      BattleHandler.switch_helper(@tier, @bot, @opponent, message, @player_one, @team)
    end
  end
end
