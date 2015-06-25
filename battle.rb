require 'json'
require 'byebug'
require './helpers.rb'
require './battle-helpers.rb'


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
    @player_one = @challenged

    message = data.split('|')
    case message[1]
    when 'request'
      @moves = get_moves(message[2]) if message[2].split(':')[0].include? "active"
      unless @have_team
        @team  << get_team_helper(message[2], @have_team).flatten.freeze
        @team.freeze
      byebug
        @have_team = true
      end
      request_helper(ws, data, @bot, @team, @have_team, room, @tier)
    when 'win','lose','tie'
      win_lose_tie_helper

    when 'faint'
      faint_helper(message[2], @bot, @team, room, @player_one, @opponent, ws)

    when 'player'
      player_helper(@bot, @opponent, data, @player_one, ws)

    when '-damage'
      damage_helper(message[2], message[3], @player_one, @bot, @opponent)

    when 'turn'
      move = decide(@moves, @bot, @opponent)
      mega_or_not(@tier, @team, @bot, ws)

    when 'switch'
      byebug
      switch_helper(@tier, @bot, @opponent, message, @player_one, @team)
    end
  end
end
