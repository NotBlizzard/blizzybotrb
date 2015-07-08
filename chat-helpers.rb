require 'faraday'
require './commands'


module ChatHelpers
  include Commands

  TEAM_URL = "https://gist.githubusercontent.com/NotBlizzard/e5e367d41e6894a8edd3/raw/0ffdcee8911d0e11c0cff9ba3c234cb93c8a29f6/team"
  TEAM = Faraday.get(TEAM_URL).body
  TIERS = ['randombattle', 'ou', 'challengecup1v1']

  def login(user, pass, id, challenge, ws)
    url = 'http://play.pokemonshowdown.com/action.php'
    if pass.empty?
      data = Faraday.get url, {:act => 'getassertion', :userid => user, :challengekeyid => id, :challenge => challenge}
      ws.send("|/trn #{user},0,#{data.body}")
    else
      data = Faraday.post url, {:act => 'login', :name => user, :pass => pass, :challengekeyid => id, :challenge => challenge}
      puts 'data is'+data.body
      data = JSON.parse(data.body.split(']')[1])
      ws.send("|/trn #{user},0,#{data['assertion']}")
    end
  end

  def send_battle_command(message, room, user,symbol, ws)
    cmd = message[3].split(symbol)[1].split(' ')[0]
    if Commands.instance_methods(false).include? cmd.downcase.to_sym
      arguments = message[3].split("#{cmd} ")[1] || ""
      ws.send("#{room}|#{self.send cmd, arguments, room, user}")
    end
  end

  def send_command(message, room, user, symbol, ws)
    if message[4].include? " "
      cmd = message[4].split(symbol)[1].split(' ')[0]
    else
      cmd = message[4].split(symbol)[1]
    end
    if Commands.instance_methods(false).include? cmd.downcase.to_sym
      arguments = message[4].split("#{cmd} ")[1] || ""
      ws.send("#{room}|#{self.send cmd, arguments, room, user}")
    end
  end

  def tournament_helper(room,message, ws)
    data = JSON.parse(message)
    if data['format'] == 'challengecup1v1'
      ws.send("#{room}|/tour join")
    end
  end

  def battle_helper(message, ws)
    data= JSON.parse(message)
    challenges_from = data['challengesFrom'].keys[0].to_s
    tier = data['challengesFrom'][challenges_from]
    if TIERS.include? tier
      ws.send("|/utm #{TEAM}")
      ws.send("|/accept #{challenges_from}")
      return tier, true
    end
  end
end
