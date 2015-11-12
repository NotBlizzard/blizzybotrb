# battle.rb - Where the battles happen.

require 'json'

require './helpers.rb'
require './battle-helpers.rb'
require './battle-parser.rb'


class Battle
  #TODO: keep track of move PP
  attr_accessor :team, :moves, :bot, :opponent, :tier, :room, :player_one
  include BattleHelpers

  def initialize(tier, bot_name)
    @bot_name = bot_name
    @tier = tier
    @player_one = true
    @team = []
    @moves = []
    @bot = {}
    @pick = ''
    @opponent = {}
    @have_team = false
    @forced_switch_moves = ['uturn', 'batonpass', 'voltswitch']
  end

  def run(ws, data, room)
    handler = BattleParser.new(ws, @bot, @opponent, @tier, data, room, @player_one)
    message = data.split('|')
    case message[1]
    when 'request'
      unless @have_team
        @team = handler.get_team(message[2])
        @have_team = true
      end
      @pick = rand(1...7)
      @pick = 1 if @tier == 'randombattle'
      handler.request(message[2], room, @pick, @moves, @team)

    when 'win','lose','tie'
      handler.win_lose_tie(room)
      if $ladder
        ws.send("|/search #{$ladder_tier}")
      end

    when 'inactive'
      if data.include? "blizzybot" # TODO: make this better
        move = decide(@moves, @bot, @opponent, @tier, @team, true)
        ws.send("#{room}|#{move}")
        if @forced_switch_moves.include? move.split(' ')[1].downcase # hackish hack
          @bot[:forced_switch] = true
          move = decide(@moves, @bot, @opponent, @tier, @team, true)
          ws.send("#{room}|#{move}")
        end
      end

    when 'faint'
      handler.faint(room, @team, @moves, @bot, @opponent)

    when 'player'
      if message[2] == 'p2' # For some reason 'p1' is skipped
        if message[3].downcase == @bot_name.downcase
          @player_one = false
        else
          @player_one = true
        end
      end
      handler.player(@moves,@team)

    when '-damage'
      handler.damage

    when 'teampreview'
      ws.send("#{room}|/team #{@pick}")
      puts "I pick #{@pick}"

    when 'turn'
      ws.send("#{room}|good luck have fun.") if message[2].to_i == 1
      move = decide(@moves, @bot, @opponent, @tier, @team)
      ws.send("#{room}|#{move}")
      if @forced_switch_moves.include? move.split(' ')[1].downcase # hackish hack
        @bot[:forced_switch] = true
        move = decide(@moves, @bot, @opponent, @tier, @team)
        ws.send("#{room}|#{move}")
      end

    when 'drag'
      if @player_one or @player_one.nil?
        if data.include? "p1a"
          @bot = handler.get_bot_switch_values(@team)
          index = @team.index(@team.find{|x| x[:name] == message[3].downcase.split(',')[0]})
          @team[0], @team[index] = @team[index], @team[0]
        else
          @opponent = handler.get_opponent_switch_values
        end
      else
        if data.include? "p1a"
          @opponent = handler.get_opponent_switch_values
        else
          index = @team.index(@team.find{|x| x[:name] == message[3].downcase.split(',')[0]})
          @team[0], @team[index] = @team[index], @team[0]
          @bot = handler.get_bot_switch_values(@team)
        end
      end

    when 'switch'
      if @player_one
        if data.include? "p1a"
          @bot = handler.get_bot_switch_values(@team)
          @moves = handler.get_moves(@bot[:moves])
        elsif data.include? "p2a"
          @opponent = handler.get_opponent_switch_values
        end
      else
        if data.include? "p1a"
          @opponent = handler.get_opponent_switch_values
        elsif data.include? "p2a"
          @bot = handler.get_bot_switch_values(@team)
          @moves = handler.get_moves(@bot[:moves])
        end
      end
    end
  end
end
