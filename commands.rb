require 'rest_client'
require 'nokogiri'
require 'open-uri'
require 'yaml'

module Commands

  $owner = YAML.load_file('config/options.yaml')['owner']
  $ranks = YAML.load_file('config/ranks.yaml')

  def can(command, user)

    if (user.match(/\W\s*#{$owner}/i)) then return true end
    groups = {  
      'unranked' => 0,
      '+' => 1,
      '%' => 2,
      '@' => 3,
      '#' => 4,
      '&' => 4,
      '~' => 5,
      'off' => 6
    }
    userrank = user[0]
    if (!$ranks.include? command or groups[$ranks[command]] == 'unranked') then return true end
    if (!groups.keys.include? userrank) then userrank = 'unranked' end
    if (groups[userrank] >= groups[$ranks[command]])
      return true
    else
      return
    end
  end

  def rank(target, user)
    if !can('rank', user) then return "" end
    if ($ranks[command].nil?) then command_rank = 'unranked' else command_rank = $ranks[command] end
    return "The current rank for #{command} is #{command_rank}."
  end

  def salt(target, user)
    if !can('salt', user) then return "" end
    return "#{target} is #{(Random.rand(0.0..100.0)).round(2)}% salty."
  end

  def reload(target, user)
    if !can('reload', user) then return "" end
    begin
      load './commands.rb'
      return "Commands reloaded."
    rescue
      return "Error."
    end
  end

  def fight(target, user)
    if !can('fight', user) then return "" end
    percent = Random.rand(0..100)
    person1 = target.split(',')[0]
    person2 = target.split(',')[1]
    if Random.rand(0..1) == 1 then userpicked = person1 else userpicked = person2 end
    message = "Hmm, if #{person1} and #{person2} were to fight, #{userpicked} would have a #{percent}% chance of winning."
    return message
  end

  def set(target, user)
    if !can('set', user) then return "" end
    command = target.split(',') [0]
    rank = target.split(',')[1]
    settable = ['helix','banlist','blacklist','dex','pick','reload','custom','urban','define','blacklistlist','gfy']
    if (!settable.include? command) then return "" end
    settableranks = ['unranked','+','%','@','#','&','~','off','']
    if (!settableranks.include? rank) then return "Have to be one of the following $ranks: #{settableranks.join(', ')}" end
    $ranks[command] = rank
    File.open('ranks.yaml','w') { |b| b.write($ranks.to_yaml)}
    return "The command #{command} is now set to #{rank}."
  end

  def about(target, user)
    return "/pm #{user}, **BlizzyBot** by: blizzardq. Made with Ruby #{RUBY_VERSION}"
  end

  def helix(target, user)
    if !can('helix', user) then return "" end
    return File.readlines('data/helix.txt').sample
  end

  def pick(target, user)
    if !can('pick', user) then return "" end
    randompick = target.split(',').sample
    return "Hmm, I randomly picked #{randompick}."
  end

  def dex(target=nil, user)
    if (!can('dex', user)) then return "" end
    if target.nil?
      target = File.readlines('data/pokemon.txt').sample.strip
    end
    begin
      url = Nokogiri::HTML(open("http://bulbapedia.bulbagarden.net/wiki/#{target.capitalize}_(Pokemon)"))
      egg = url.css('a[href="/wiki/Species"]')[0].content
      flavor_text = url.css('td[rowspan="1"]')[-1].content
      return "#{target.capitalize}, the #{egg}. #{flavor_text}"
    rescue
      return "Seems like there is no Pokemon named #{target.capitalize}."
    end
  end

  def urban(target=nil, user)
    if !can('urban',user) then return "" end
    if word.nil?
      url = "http://api.urbandictionary.com/v0/random"
    else
      url = "http://api.urbandictionary.com/v0/define?term=#{word}"
    end
    urban = RestClient.get url
    return "#{urban['list'][0]['word']}: #{urban['list'][0]['definition'].strip.gsub('[','').gsub(']','').gsub("\n",'')}"
  end

  def custom(target, user)
    #if !can('custom', user) then return "" end
    if ((target.include? '/transferbucks' or target.include? '/tb') and (!user.match(/#{$owner}/i)))
      return ""
    else
      return target
    end
  end

  def define(target, user)
    if !can('define', user) then return "" end
    begin
      dictionary = Nokogiri::HTML(open("http://www.dictionary.reference.com/browse/#{target.downcase}"))
      return "#{target}: #{dictionary.css('.def-content')[0].content.strip}"
    rescue
      return "#{target} is not a word."
    end
  end
end
