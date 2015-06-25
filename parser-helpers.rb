require 'faraday'
require './commands'


module ParserHelpers
  def login(user, pass, id, challenge, ws)
    url = 'http://play.pokemonshowdown.com/action.php'
    if pass.empty?
      data = Faraday.get url, {:act => 'getassertion', :userid => user, :challengekeyid => id, :challenge => challenge}
      ws.send("|/trn #{user},0,#{data.body}")
    else
      data = Faraday.post url, {:act => 'login', :name => user, :pass => pass, :challengekeyid => id, :challenge => challenge}
      data = JSON.parse(data.body.split(']')[1])
      ws.send("|/trn #{user},0,#{data['assertion']}")
    end
  end

  def send_battle_command(message, room, user,symbol, ws)
    begin
      cmd = message[3].split(symbol)[1].split(' ')[0]
      arguments = message[3].split("#{cmd} ")[1] || nil
      ws.send("#{room}|#{self.send cmd, arguments, room, user}")
    rescue
    end
  end

  def send_command(message, room, user, symbol, ws)
    begin
      cmd = message[4].split(symbol)[1].split(' ')[0]
      arguments = message[4].split("#{cmd} ")[1] || nil
      ws.send("#{room}|#{self.send cmd, arguments, room, user}")
    rescue
    end
  end

  def battle_helper(message, ws)
    from = JSON.parse(message)
    if message.include? "challengecup1v1"
      ws.send("|/accept #{from['challengesFrom'].invert['challengecup1v1']}")
      tier = 'cc1v1'
      return tier
    elsif message.include? 'randombattle'
      ws.send("|/accept #{from['challengesFrom'].invert['randombattle']}")
      tier = 'randombattle'
      return tier
    elsif message.include? 'ou'
      ws.send("|/useteam #{TEAM}")
      ws.send("|/accept #{from['challengesFrom'].invert['ou']}")
      tier = 'ou'
      return tier

    end
  end
end