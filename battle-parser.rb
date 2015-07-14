
MOVES               = JSON.parse(Faraday.get("https://gist.githubusercontent.com/NotBlizzard/bbebc81b2bae1f506514/raw/7de50703899d08c598e776623bdfebadd9f42ba8/moves.json").body)
WEAKNESSES          = JSON.parse(Faraday.get("https://gist.githubusercontent.com/NotBlizzard/f2e72ad079b6a211c2b0/raw/a734064c23cea6027f9c720afdc6376c8e6ee9e5/weaknesses.json").body)
POKEDEX             = JSON.parse(Faraday.get("https://gist.githubusercontent.com/NotBlizzard/a84ad1737c801f748b01/raw/69dc8756a924aa846a4673c591ebf37a0fc60980/pokedex.json").body)
SUPER_EFFECTIVENESS = JSON.parse(Faraday.get("https://gist.githubusercontent.com/NotBlizzard/dede16ec50b4d4693b2d/raw/1e117b0ffb98ba0fa47d6b5f0da9d52a537266ae/supereffectiveness.json").body)
RESISTANCES         = JSON.parse(Faraday.get("https://gist.githubusercontent.com/NotBlizzard/cc46e43ac6df8e87e1f9/raw/84e8164a2a92bed7ca81fc7df503209975a1fef6/resistances.json").body)
IMMUNITIES          = JSON.parse(Faraday.get("https://gist.githubusercontent.com/NotBlizzard/ae9017358a93d49ad25f/raw/64a3961aaa8b0697c815b340eec164eec7e0e4e2/immunities.json").body)

require 'json'

class BattleParser
  include BattleHelpers
  attr_accessor :ws, :bot, :opponent, :team, :data

  def initialize(ws, bot, opponent, tier, data, room, player_one)
    @ws = ws
    @tier = tier
    @data = data
    @room = room
    @bot = bot
    @opponent = opponent
    @megaed = false
    @messages = data.split('|')
    @player_one = player_one
  end

  def win_lose_tie(room)
    @ws.send("#{room}|good game")
    @ws.send("#{room}|/part")
  end


  def faint(room, team, moves, bot, opponent)
    pkmn = @messages[2].split(': ')[1].downcase
    if @player_one
      if @data.include? "p1a: "
        team.find{|x| x[:nick] == pkmn}[:fainted] = true
        @bot[:hp] = 0
        move = decide(moves, @bot, opponent, @tier, team)
        ws.send("#{room}|#{move}")
      end
    else
      if @data.include? "p2a: "
        team.find{|x| x[:nick] == pkmn}[:fainted] = true
        @bot[:hp] = 0
        move = decide(moves, @bot, opponent, @tier, team)
        ws.send("#{room}|#{move}")
      end
    end
  end

  def get_bot_switch(team)
    if @player_one
      if @data.include? "p1a"
        bot = self.get_bot_switch_values(team)
        bot
      end
    else
      if @data.include? "p2a"
        bot = self.get_bot_switch_values(team)
        bot
      end
    end
  end

  # TODO: merge commands

  def player(moves, team)
    if @player_one
      if @data.include? "p2a: "
        @bot = self.get_bot_player(team, 'p1')
        @opponent = self.get_opponent_player(@data, 'p2')
        #TODO: change to Mega_or_not
        move = decide(moves, @bot, @opponent, @tier, team)
        @ws.send("#{room}|#{move}")
      end
    else
      if @data.include? 'p2a: '
        @bot = self.get_bot_player(team, 'p2')
        @opponent = self.get_opponent_player(@data, 'p1')
        move = decide(moves, @bot, @opponent, @tier, team)
        @ws.send("#{room}|#{move}")
      end
    end
  end

   def get_bot_player(team, p1_split)
    you = {}
    you[:name] = @data.split("#{p1_split}a: ")[1].split('|')[0].downcase.gsub(/[^A-z0-9]/, '')
    you[:item] = team.find{|x| x[:name] == you[:name]}[:item]
    you[:type] = POKEDEX[you[:name]]['types'].map(&:downcase)
    you[:speed] = POKEDEX[you[:name]]['baseStats']['spe']
    return you
  end

  def get_opponent_player(p2_split)
    opponent = {}
    opponent[:name] = @data.split("#{p2_split}a: ")[1].split('|')[0].downcase.gsub(/[^A-z0-9]/, '')
    opponent[:type] = POKEDEX[opponent[:name]]['types'].map(&:downcase)
    opponent[:speed] = POKEDEX[opponent[:name]]['baseStats']['spe']
    return opponent
  end

  def get_bot_switch_values(team)
    you = {}
    you[:hp] = @messages[4].to_i
    you[:name] = @messages[3].split(',')[0].downcase.gsub(/[^a-z0-9]/,'')
    you[:type] = POKEDEX[you[:name]]['types'].map(&:downcase)
    you[:ability] = team.find{|x| x[:name] == you[:name]}[:ability]
    you[:moves] = team.find{|x| x[:name] == you[:name]}[:moves]
    you[:item] = team.find{|x| x[:name] == you[:name]}[:item]
    you[:speed] = POKEDEX[you[:name]]['baseStats']['spe']
    return you
  end

  def get_opponent_switch_values
    opponent = {}
    opponent[:hp] = @messages[4].to_i
    opponent[:name] = @messages[3].split(',')[0].downcase.gsub(/[^a-z0-9]/,'')
    # Hacky hack is hack.
    if opponent[:name].include? 'hoopa'
      opponent[:name] = 'hoopa'
    end
    opponent[:type] = POKEDEX[opponent[:name]]['types']
    opponent[:speed] = POKEDEX[opponent[:name]]['baseStats']['spe']
    return opponent
  end


  def get_hp
    message = @messages[3]
    hp = Rational(message.split('/')[0]) / message.split('/')[1].to_f
    if data.include? " "
      hp = Rational(message.split('/')[0]) / message.split('/')[1].split(' ')[0].to_f
    end
    return hp
  end

  def get_bot_request(data)
    data = JSON.parse(data)
    you = {}
    you[:item] = data['side']['pokemon'][0]['item']
    you[:mega] = data['side']['pokemon'][0]['canMegaEvo']
    you[:ability] = data['side']['pokemon'][0]['ability']
    you[:name] = data['side']['pokemon'][0]['details'].split(',')[0].gsub(/[^A-z0-9]/,'')
    you[:type] = POKEDEX[you[:name].downcase]["types"]
    you[:moves] = data['side']['pokemon'][0]['moves']
    return you
  end

  def get_team(message)
    team = []
    data = JSON.parse(message)
    data['side']['pokemon'].each do |pkmn|
      team << {
        :nick    => pkmn['ident'].split(': ')[1].downcase,
        :name    => pkmn['details'].split(',')[0].gsub(/[^A-z0-9]/, '').downcase,
        :moves   => pkmn['moves'],
        :item    => pkmn['item'].downcase,
        :ability => pkmn['baseAbility'].downcase,
        :mega    => pkmn['canMegaEvo'],
        :speed   => pkmn['stats']['spe'],
        :type    => POKEDEX[pkmn['details'].split(',')[0].downcase.gsub(/[^a-z0-9]/,'')]['types'].map(&:downcase),
        :fainted => false
      }
    end
    puts "team in method is now #{team}"
    team
  end

  def get_moves(moves)
    # Moves array to hold moves.
    m = []
    puts "Moves are #{moves}"
    moves.each do |move|
      move = move.downcase.gsub(/[^a-z]/,'')
      m << {
        :name     => move,
        :type     => MOVES[move]['type'].downcase,
        :power    => MOVES[move]['basePower'],
        :priority => MOVES[move]['priority']
      }
    end
    return m
  end


  def request(message, room, pick, moves, team)
    @ws.send("#{room}|/team #{pick}") if @tier == 'cc1v1' or @tier == 'ou'
    unless message.include? 'side'
      @bot = get_bot_request(message)
    end
    if message.include? 'forceSwitch'
      forced_pkmn = JSON.parse(message)['side']['pokemon'][0]['details'].split(',')[0].downcase.gsub(/[^a-z0-9]/,'')
      puts "#{forced_pkmn} must switch"
      forced_pkmn = forced_pkmn.split('mega')[0] if forced_pkmn.include? 'mega'
      team.find {|x| x[:name] == forced_pkmn}[:forced_to_switch] = true
      move = decide(moves, @bot, @opponent, @tier, team)
    end
  end

  def damage
    if @player_one
      if @messages[2].include? "p1a"
        if @messages[3].include? 'fnt'
          @bot[:hp] = 0
        else
          @bot[:hp] = self.get_hp
        end
      end
    else
      if @messages[3].include? 'fnt'
        @opponent[:hp] = 0
      else
        @opponent[:hp] = self.get_hp
      end
    end
  end
end
