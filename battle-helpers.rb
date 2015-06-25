require 'byebug'
require 'faraday'

module BattleHelpers

  # Constants
  MOVES               = JSON.parse(Faraday.get("https://gist.githubusercontent.com/NotBlizzard/bbebc81b2bae1f506514/raw/7de50703899d08c598e776623bdfebadd9f42ba8/moves.json").body)
  WEAKNESSES          = JSON.parse(Faraday.get("https://gist.githubusercontent.com/NotBlizzard/f2e72ad079b6a211c2b0/raw/a734064c23cea6027f9c720afdc6376c8e6ee9e5/weaknesses.json").body)
  POKEDEX             = JSON.parse(Faraday.get("https://gist.githubusercontent.com/NotBlizzard/a84ad1737c801f748b01/raw/69dc8756a924aa846a4673c591ebf37a0fc60980/pokedex.json").body)
  SUPER_EFFECTIVENESS = JSON.parse(Faraday.get("https://gist.githubusercontent.com/NotBlizzard/dede16ec50b4d4693b2d/raw/1e117b0ffb98ba0fa47d6b5f0da9d52a537266ae/supereffectiveness.json").body)
  RESISTANCES         = JSON.parse(Faraday.get("https://gist.githubusercontent.com/NotBlizzard/cc46e43ac6df8e87e1f9/raw/84e8164a2a92bed7ca81fc7df503209975a1fef6/resistances.json").body)
  IMMUNITIES          = JSON.parse(Faraday.get("https://gist.githubusercontent.com/NotBlizzard/ae9017358a93d49ad25f/raw/64a3961aaa8b0697c815b340eec164eec7e0e4e2/immunities.json").body)

  # Effectiveness: Returns what said types (in total) are weak, immunue, and reistant against.
  def effectiveness(types)
    weak_against = []
    resist_against = []
    immune_against = []
    types.each do |type|
      weak_against << WEAKNESSES[type]
      resistant_against << RESISTANCES[type]
      immune_against << IMMUNITIES[type]
    end
    weak_against.flatten!
    resist_against.flatten!
    immune_against.flatten!
    weak_against.each do |type|
      if resist_against.include? type
        resist_against.delete(type)
        weak_against.delete(type)
      end
    end
    immune_against.each do |type|
      if weak_against.include? type
        weak_against.delete(type)
      end
    end

    return {:weak => weak_against.uniq.map(&:to_s), :immune => immune_against.map(&:to_sym), :resist => resist_against.uniq.map(&:to_s)}
  end

  # Gets the moves of the Pokemon using JSON data
  def get_moves(data)
    data = JSON.parse(data)
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

  # -----_helper: Used for parsing the messages in the battle.

  def request_helper(ws, data, bot, team, have_team, room, tier)
    ws.send("#{room}|good luck have fun.")
    ws.send("#{room}|/team #{rand(1...7)}")if tier == 'cc1v1' or tier == 'ou'
    if data.include? 'side'
     m = data.split('|')
      if have_team == false
        have_team = true
      else
        bot = get_bot_request(m[2])
      end
    end
  end

  def damage_helper(data_1, data_2, player_one, bot, opponent)
    if player_one
      if data_1.include? "p1a"
        if data_2.include? 'fnt'
          bot[:hp] = 0
        else
          bot[:hp] = get_hp(data_2)
        end
      end
    else
      if data_2.include? 'fnt'
        opponent[:hp] = 0
      else
        opponent[:hp] = get_hp(data_2)
      end
    end
  end


  def win_lose_tie_helper(ws)
    ws.send("#{room}|good game")
    ws.send("#{room}|/part")
  end


  def faint_helper(data, bot, team, room, player_one, opponent, ws)
    pkmn = data.split(': ')[1]
    if player_one
      if data.include? "p1a: "
        team.find{|x| x[:nick] == pkmn}[:fainted] = true
        bot[:hp] = 0
        move = decide(moves, bot, opponent)
        ws.send("#{room}|#{move}")
      end
    end
  end

  def switch_helper(tier, bot, opponent, data, player_one, team)
    if player_one
      if data[2].include? 'p1a'
        unless tier == 'cc1v1'
          bot = get_bot_switch(data[3], team)
        end
      else
       opponent = get_opponent_switch(data[3])
      end
    else
      if data[2].include? 'p2a'
        unless tier == 'cc1v1'
          bot = get_bot_switch(data[3], team)
        end
      else
       opponent = get_opponent_switch(data[3])
      end
    end
  end

  def player_helper(bot, opponent, data, player_one, ws)
    if player_one and data.include? "p2a: "
      bot = get_bot_player(d, team, 'p1')
      opponent = get_opponent_player(d, 'p2')
      move = decide(moves, bot, opponent)
      ws.send("#{room}|#{move}")
    end
  end

  def get_team_helper(data, current_team)
    team = []
    data = JSON.parse(data)
      unless current_team
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
    end
    return team
  end

  def decide(moves, bot, opponent)
    moves_power = []
    strongest = ''
    opponent_weaknesses  = []
    opponent_resistances = []
    opponent_immunities  = []

    opponent[:type].each do |p|
      opponent_weaknesses  << WEAKNESSES[p.downcase]
      opponent_resistances << RESISTANCES[p.downcase]
      opponent_immunities  << IMMUNITIES[p.downcase]
    end

    opponent_abilities   = POKEDEX[opponent[:name].downcase]['abilities'].values.flatten.map(&:downcase)
    opponent_weaknesses  = opponent_weaknesses.flatten.map(&:downcase).uniq
    opponent_resistances = opponent_resistances.flatten.map(&:downcase).uniq
    opponent_immunities  = opponent_immunities.flatten.map(&:downcase).uniq

    moves.each do |move|
      mod = 1
      counts = Hash.new 0
      if you[:type].include? move[:type]
        mod += 0.5
      end
      opponent_weaknesses.each {|x| counts[x] += 1}
      if counts[move[:type]] == 2
        mod += 3
      elsif counts[move[:type]] == 1
        mod += 1
      end
      counts = Hash.new 0
      opponent_resistances.each {|x| counts[x] += 1}
      if counts[move[:type]] == 2
        mod -= 1.5
      elsif counts[move[:type]] == 1
        mod -= 0.5
      end
      if opponent_immunities.include? move[:type]
        mod = 0
      end

      unless moves_power.length >= 4
        moves_power << {:power => move[:power] * mod, :name => move[:name], :mod => mod}
        moves_power = moves_power
      end
      # Allow Sigilyph to set up.
      if you[:name].downcase == 'sigilyph'
        return "/move #{['cosmicpower', 'storedpower'].sample}"
      end
    end

    strongest = moves_power.max_by {|x| x[:power]}
    strongest = {:power => 0,:mod => 0,:name => ''}  if strongest.nil? or strongest.empty?

    # Check if the mod is less than 1, if opp has type adv, or pokemon fainted.
    if ((strongest[:mod].to_i < 1) and (tier != 'cc1v1')) or (opp[:type] & effectiveness(you[:type])[:weak].map(&:to_s)).any? or you[:hp] <= 0
      puts 'in loop'
      opp[:type].each do |type|
        team.each_with_index do |member, i|
          opp[:type] = opp[:type].map(&:downcase)
          if ( effectiveness(opp[:type])[:weak].map(&:to_s) & member[:type].map(&:to_s) ).any?
            team[0], team[i] = team[i], team[0]
            return "/switch #{i.to_i+1}"
          end
        end
      end
    end

    "/move #{strongest[:name].downcase}"
  end

  def get_bot_player(data, team, p1_split)
    you = {}
    you[:name] = data.split("#{p1_split}a: ")[1].split('|')[0].downcase.gsub(/[^A-z0-9]/, '')
    you[:item] = team.find{|x| x[:name] == you[:name]}[:item]
    you[:type] = POKEDEX[you[:name]]['types'].map(&:downcase)
    you[:speed] = POKEDEX[you[:name]]['baseStats']['spe']
    return you
  end

  def get_opponent_player(data, p2_split)
    opponent = {}
    opponent[:name] = data.split("#{p2_split}a: ")[1].split('|')[0].downcase.gsub(/[^A-z0-9]/, '')
    opponent[:type] = POKEDEX[opponent[:name]]['types'].map(&:downcase)
    opponent[:speed] = POKEDEX[opponent[:name]]['baseStats']['spe']
    return opponent
  end

  def get_bot_switch(data, team)
    you = {}
    you[:name] = data.split(',')[0].downcase.gsub(/[^A-z0-9]/,'')
    you[:type] = POKEDEX[you[:name]]['types'].map(&:downcase)

    you[:item] = team.find{|x| x[:name] == you[:name]}[:item]
    you[:speed] = POKEDEX[you[:name]]['basestats']['spe']
    return you
  end

  def get_opponent_switch(data)
    opponent = {}
    opponent[:name] = data.split(',')[0].downcase.gsub(/[^A-z0-9]/,'')
    opponent[:type] = POKEDEX[opponent[:name]]['types']
    opponent[:speed] = POKEDEX[opponent[:name]]['basestats']['spe']
    return opponent
  end


  def get_hp(data)
    hp = Rational(data.split('/')[0]) / data.split('/')[1].to_f
    if data.include? " "
      hp = Rational(data.split('/')[0]) / datasplit('/')[1].split(' ')[0].to_f
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

  def mega_or_not(tier, team, you, ws)
    unless tier == 'cc1v1'
      if team.find{|x| x[:name].downcase == you[:name]}[:mega] == true
        if megaed == false
          ws.send("#{room}|#{move} mega")
          magaed = true
        end
      else
        ws.send("#{room}|#{move}")
      end
    else
      if you[:mega] == true
        ws.send("#{room}|#{move} mega")
      else
        ws.send("#{room}|#{move}")
      end
    end
    ws.send("#{room}|#{move}")
  end
end