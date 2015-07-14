require 'json'
require 'byebug'
require './helpers.rb'
require './battle-helpers.rb'
require './battle-parser.rb'


class Battle
  attr_accessor :team, :moves, :bot, :opponent, :tier, :room, :player_one
  include BattleHelpers

  def initialize(tier, player_one)
    @tier = tier
    @team = []
    @moves = []
    @bot = {}
    @pick = ''
    @opponent = {}
    @player_one = player_one
    @have_team = false
  end

  def run(ws, data, room)
    handler = BattleParser.new(ws, @bot, @opponent, @tier, data, room, @player_one)
    message = data.split('|')
    case message[1]
    when 'request'
      unless @have_team
        @team = handler.get_team(message[2])
        File.open('d.json','a') {|a| a.write(@team.to_json)}
        @have_team = true
      end
      @pick = 1 if @tier == 'randombattle'
      handler.request(message[2], room, @pick, @moves, @team)

    when 'win','lose','tie'
      handler.win_lose_tie(room)

    when 'faint'
      handler.faint(room, @team, @moves, @bot, @opponent)

    when 'player'
      if message[2] == 'p1'
        if message[3] =~ /\W#{@user}/
          @player_one = true
        else
          @player_one = false
        end
      end
      handler.player(@moves,@team)

    when '-damage'
      handler.damage

    when 'teampreview'
      ws.send("#{room}|good luck have fun. I am a bot.")
      ws.send("#{room}|/team #{@pick}")
      puts "I picked #{@pick}"

    when 'turn'
      ws.send("#{room}|good luck have fun. I am a bot.") if message[2].to_i == 1 and @tier == 'cc1v1'
      move = decide(@moves, @bot, @opponent, @tier, @team)
      ws.send("#{room}|#{move}")

    when 'drag'
      @bot = handler.get_bot_switch_values(@team)

    when 'switch'
      if @player_one
        if data.include? "p1a"
          @bot = handler.get_bot_switch_values(@team)
          @moves = handler.get_moves(@bot[:moves])
        else
          @opponent = handler.get_opponent_switch_values
        end
      else
        if data.include? "p1a"
          @opponent = handler.get_opponent_switch_values
        else
          @bot = handler.get_bot_switch_values(@team)
          @moves = handler.get_moves(@bot[:moves])
        end
      end
    end
  end
end
