require 'json'
require 'byebug'
require './helpers.rb'
require './battle-helpers.rb'
require './battle-parser.rb'


class Battle
  attr_accessor :team, :moves, :bot, :opponent, :tier, :room
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
    handler = BattleParser.new(ws, @bot, @opponent, @tier, data, room)
    @player_one = @challenged

    message = data.split('|')
    case message[1]
    when 'request'
      @moves = handler.get_moves if message[2].split(':')[0].include? "active"
      unless @have_team
        @team = handler.get_team(message[2])
        @team.freeze
        # Ugly hack is ugly
        @team_holder = @team
        @have_team = true
      end
      handler.request(message[2], @room)

    when 'win','lose','tie'
      handler.win_lose_tie(room)

    when 'faint'
      handler.faint(room, @team)

    when 'player'
      handler.player(@moves,@team)

    when '-damage'
      handler.damage

    when 'turn'
      byebug
      move = decide(@moves, @bot, @opponent)
      handler.mega_or_not(@team, @bot, ws)

    when 'switch'
      puts "Team Here is now #{@team}"
      handler.switch(@team)
    end
  end
end
