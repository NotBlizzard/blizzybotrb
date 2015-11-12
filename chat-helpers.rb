require 'faraday'
require './commands'

TIERS = ['randombattle', 'ou', 'challengecup1v1','uu', 'ubers','lc']

module ChatHelpers
  include Commands

  UBERS_TEAM = Faraday.get("https://gist.githubusercontent.com/NotBlizzard/06870af3a26023d55bf6/raw/8f6b58f0de4bd39c02d4e35e47e03a250349782f/gistfile1.txt").body
  OU_TEAM 	 = Faraday.get("https://gist.githubusercontent.com/NotBlizzard/e5e367d41e6894a8edd3/raw/0ffdcee8911d0e11c0cff9ba3c234cb93c8a29f6/team").body
  UU_TEAM    = Faraday.get("https://gist.githubusercontent.com/NotBlizzard/8ef119944cae1b75625a/raw/3dd52257ed87698b87e099cc0bb2c5ea8d6d0ece/uuteam").body
  LC_TEAM    = Faraday.get("https://gist.githubusercontent.com/NotBlizzard/0289a7efb96d1eea2d29/raw/36d28588ef61bd2bc57cc9eb471519aa862e804e/gistfile1.tx").body

  def login(user, pass, id, challenge, ws)
    url = 'http://play.pokemonshowdown.com/action.php'
    if pass.empty?
      data = RestClient.get url, {:act => 'getassertion', :userid => user, :challengekeyid => id, :challenge => challenge}
      ws.send("|/trn #{user},0,#{data.body}")
    else
      data = Faraday.post url, {:act => 'login', :name => user, :pass => pass, :challengekeyid => id, :challenge => challenge}
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
    begin
      if Commands.instance_methods(false).include? cmd.downcase.to_sym
        arguments = message[4].split("#{cmd} ")[1] || ""
        ws.send("#{room}|#{self.send cmd, arguments, room, user}")
      end
    rescue
    end
  end

  def tournament_helper(room,message, ws)
    data = JSON.parse(message)
    if TIERS.include? data['format']
      ws.send("#{room}|/tour join")
    end
  end

  def battle_helper(message, ws)
    data= JSON.parse(message)
    if data['challengeTo'].nil?
      challenges_from = data['challengesFrom'].keys[0].to_s
      tier = data['challengesFrom'][challenges_from]
      if TIERS.include? tier
        case tier
        when 'ou'
          ws.send("|/utm #{OU_TEAM}")
        when 'uu'
          ws.send("|/utm #{UU_TEAM}")
        when 'ubers'
          ws.send("|/utm #{UBERS_TEAM}")
        when 'lc'
          ws.send("|/utm #{LC_TEAM}")
        end
        ws.send("|/accept #{challenges_from}")
        return tier, true
      else
        puts challenges_from
        ws.send("|/pm #{challenges_from}, The tiers I play are #{TIERS.join(', ')}")
      end
    else
      tier = data['challengeTo'].values[1]
      return tier, false
    end
  end
end
