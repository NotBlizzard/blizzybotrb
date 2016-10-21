module Commands
  def can(user, command, bot)
    user_rank = user[0]
    if user_rank.match(/[A-z0-9]/).nil?
      user = user[1..-1].gsub(/[^A-z0-9]/, "")

      return true if bot.admins.include? user

      rank_data = JSON.parse(File.read("./data/ranks.json"))

      return true if rank_data[command].nil?

      ranks = {
        " " => 0,
        "+" => 1,
        "%" => 2,
        "@" => 3,
        "&" => 4,
        "~" => 5
      }

      if ranks[user_rank] >= rank_data[command]
        true
      else
        false
      end
    else
      false
    end
  end

  def js(args, room, user, bot)
    can(user, __callee__, bot)
    puts args
    `node -p "#{args}"`
  end


  def vaporwave(args, room, user, bot)
    args.split('').map { |i| "#{i} " }.join.chop
  end

  def echo(args, room, user, bot)
    return false if !can(user, __callee__, bot)
    args
  end

  def set(args, room, user, bot)
    return false if !can(user, __callee__, bot)
    commands = Commands.instance_methods.map(&:to_s).delete_if { |i| ["can", "set"].include? i }
    rank_data = JSON.parse(File.read("./data/ranks.json"))
    command = args[0]
    rank = args[1]
    unless rank.is_a? Integer
      return "'#{rank}' is not a valid rank. rank must be a number between 0 and 5 (0 being normal user, 5 being administrator)."
    end
    ranks = {
      " " => 0,
      "+" => 1,
      "%" => 2,
      "@" => 3,
      "&" => 4,
      "~" => 5
    }
    unless commands.include? command
      return "'#{command}' is not a valid command."
    end
    rank_data[command] = rank
    File.open("./data/ranks.json", "w") do |f|
      f.write(rank_data.to_json)
    end
    "'#{command}' has been set to '#{rank}'."
  end

  def ptcg(args, room, user, bot)
    args = args.gsub(', ', ',').split(',')
    if args[1].nil?
      return "You must specify the set."
    end
    if args[0][-2..-1].downcase == "ex"
      args[0] = "#{args[0][0..-3]}-#{args[0][-2..-1]}"
    end
    begin
      url = "https://api.pokemontcg.io/v1/cards?name=#{args[0].downcase.gsub(/ /, '+')}"
      data = JSON.parse(RestClient.get(url))
      pokemon = data["cards"].select { |i| i["set"].gsub(/ /, "").downcase == args[1].gsub(/ /, "").downcase }[0]
      return "bulbapedia.bulbagarden.net/wiki/#{pokemon["name"].gsub(/ /, '_')}_(#{pokemon["set"].gsub(/ /, "_")}_#{pokemon["number"]})"
    rescue
      return "`#{args[0]}` is not a valid Pokemon the Trading Card Game card."
    end
  end

  def mtg(args, room, user, bot)
    return false if !can(user, __callee__, bot)
    begin
      url = "https://api.deckbrew.com/mtg/cards/#{args.downcase.gsub(/ /, "-")}"
      return "http://gatherer.wizards.com/Pages/Card/Details.aspx?multiverseid=#{JSON.parse(RestClient.get(url))["editions"][0]["multiverse_id"]}"
    rescue
      return "'#{args[0]}' is not a valid Magic the Gathering card."
    end
  end

  def e(args, room, user, bot)
    return false if !can(user, __callee__, bot)
    if room.include? "battle-"
      battle = bot.current_battle
      return eval("#{args}")
    else
      return eval("#{args}")
    end
  end

  def about(args, room, user, bot)
    "BlizzyBot: a Pokemon Showdown bot written in Ruby by BlizzardQ"
  end

  def reload(args, room, user, bot)
    return false if !can(user, __callee__, bot)

    case args
    when "commands"
      load "#{Dir.pwd}/commands.rb"
    when "battles"
      Dir['./battle/util/*.rb'].each { |file| load file }
      load "#{Dir.pwd}/battle/battle.rb"
    when "bot"
      load "#{Dir.pwd}/bot.rb"
    else
      return "Not a valid module."
    end
    puts "args are #{args[0]}"
    "'#{args}' have been reloaded."
  end
end
