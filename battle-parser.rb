class BattleParser
  attr_accessor :ws, :bot, :opponent, :team, :data

  def intialize(ws, bot, opponent, tier, data)
    @ws = ws
    @tier = tier
    @data = data
    @megaed = false
    @messages = data.split('|')
    @player_one = true
  end

  def win_lose_tie(room)
    ws.send("#{room}|good game")
    ws.send("#{room}|/part")
  end


  def faint(room, team)
    pkmn = @messages[2].split(': ')[1]
    if @player_one
      if @data.include? "p1a: "
        team.find{|x| x[:nick] == pkmn}[:fainted] = true
        @bot[:hp] = 0
        move = BattleHelpers.decide(moves, bot, opponent)
        ws.send("#{room}|#{move}")
      end
    end
  end

  def switch
    if @player_one
      if @messages[2].include? 'p1a'
        unless tier == 'cc1v1'
          @bot = get_bot_switch(@messages[3], team)
        end
      else
       @opponent = self.get_opponent_switch(@messages[3])
      end
    else
      if @messages[2].include? 'p2a'
        unless tier == 'cc1v1'
          @bot = self.get_bot_switch(@messages[3], team)
        end
      else
       @opponent = self.get_opponent_switch(@messages[3])
      end
    end
  end

  def player(moves, team)
    if @player_one and @data.include? "p2a: "
      @bot = self.get_bot_player(team, 'p1')
      @opponent = self.get_opponent_player(@data, 'p2')
      move = BattleHelpers.decide(moves, @bot, @opponent)
      ws.send("#{room}|#{move}")
    else
      @bot = self.get_bot_player(team, 'p2')
      @opponent = self.get_opponent_player(@data, 'p1')
      move = BattleHelpers.decide(moves, @bot, @opponent)
      ws.send("#{room}|#{move}")
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

  def get_bot_switch(data, team)
    you = {}
    you[:name] = @data.split(',')[0].downcase.gsub(/[^A-z0-9]/,'')
    you[:type] = POKEDEX[you[:name]]['types'].map(&:downcase)
    you[:item] = team.find{|x| x[:name] == you[:name]}[:item]
    you[:speed] = POKEDEX[you[:name]]['basestats']['spe']
    return you
  end

  def get_opponent_switch(data)
    @opponent = {}
    opponent[:name] = data.split(',')[0].downcase.gsub(/[^A-z0-9]/,'')
    opponent[:type] = POKEDEX[opponent[:name]]['types']
    opponent[:speed] = POKEDEX[opponent[:name]]['baseStats']['spe']
    return opponent
  end


  def get_hp which_message
    if which_message == 2
      message = @messages[2]
    else
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
    you[:name] = data['side']['pokemon'][0]['details'].split(',')[0].gsub(/[^A-z0-9]/,'')
    you[:type] = POKEDEX[you[:name].downcase]["types"]
    you[:moves] = data['side']['pokemon'][0]['moves']
    return you
  end

  def mega_or_not(team, moves)
    move = BattleHandler.decide(moves, @bot, @opponent)
    unless @tier == 'cc1v1'
      if team.find{|x| x[:name].downcase == @bot[:name]}[:mega] == true
        if @megaed == false
          @ws.send("#{room}|#{move} mega")
          @magaed = true
        end
      else
        @ws.send("#{room}|#{move}")
      end
    else
      if @bot[:mega] == true
        @ws.send("#{room}|#{move} mega")
      else
        @ws.send("#{room}|#{move}")
      end
    end
    @ws.send("#{room}|#{move}")
  end
end


  def get_team
    team = []
    data = JSON.parse(@messages[2])
      for x in 0..5 do
        team << {
          :nick     => data['side']['pokemon'][x]['ident'].split(': ')[1].downcase,
          :name     => data['side']['pokemon'][x]['details'].split(',')[0].gsub(/[^A-z0-9]/,'').downcase,
          :moves    => data['side']['pokemon'][x]['moves'].to_a.map(&:downcase),
          :item     => data['side']['pokemon'][x]['item'].downcase,
          :ability  => data['side']['pokemon'][x]['baseAbility'].downcase,
          :mega     => data['side']['pokemon'][x]['canMegaEvo'],
          :speed    => data['side']['pokemon'][x]['stats']['spe'],
          :fainted  => false,
          # For some reason we have to do this the hard way.
          :type     => POKEDEX[data['side']['pokemon'][x]['details'].split(',')[0].downcase.gsub(/[^A-z0-9]/,'')]['types'].map(&:downcase)
        }
      end
    team
  end

  def moves_helper
    data = JSON.parse(@messages[2])
    moves = []
    data['active'][0]['moves'].each_with_index do |_, i|
      moves << {
        :name     => data['active'][0]['moves'][i]['id'],
        :type     => MOVES[data['active'][0]['moves'][i]['id'].downcase.gsub('-','')]['type'].downcase,
        :power    => MOVES[data['active'][0]['moves'][i]['id'].downcase.gsub('-','')]['basepower'],
        :priority => MOVES[data['active'][0]['moves'][i]['id'].downcase.gsub('-','')]['priority']
      }
    end
    return moves
  end


  def request
    @ws.send("#{room}|good luck have fun.")
    @ws.send("#{room}|/team #{rand(1...7)}")if tier == 'cc1v1' or tier == 'ou'
    if @messages[2].include? 'side'
      if have_team == false
        have_team = true
      else
        @bot = get_bot_request(m[2])
      end
    end
  end

  def damage
    if @player_one
      if @messages[2].include? "p1a"
        if @message[3].include? 'fnt'
          @bot[:hp] = 0
        else
          @bot[:hp] = self.get_hp 2
        end
      end
    else
      if @messages[3].include? 'fnt'
        @opponent[:hp] = 0
      else
        @opponent[:hp] = self.get_hp_3
      end
    end
  end
end