require 'rest_client'
require 'nokogiri'
require 'open-uri'
require 'yaml'
require 'cgi'

require './parser.rb'

class String
  $owner = YAML.load_file('config/options.yaml')['owner']
  $ranks = YAML.load_file('config/ranks.yaml')
    
  def can(command)
    if (self.match(/\W\s*#{$owner}/i)) then return true end
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
    rank = self[0]
    if (!$ranks.include? command or groups[$ranks[command]] == 'unranked') then return true end
    if (!groups.keys.include? rank) then rank = 'unranked' end
    if (groups[rank] >= groups[$ranks[command]])
      return true
    else
      return false
    end
  end
end

def dice(target=nil, user)
  return '' unless user.can('dice')
  if target.nil?
    return "1 6-sided Die: #{Random.rand(1..6)}"
  else
    if target.include? 'd'
      target = target.to_s.split('d')
      dice = target[0].to_i
      range = target[1].to_i
      if dice > 20
        return "Too many dice."
      elsif range > 99
        return "Range can't be over 99."
      end
      rolls = []
      dice.times do 
        rolls << Random.rand(1..range.to_i)
      end
      return "#{dice} #{range}-sided Dice: #{rolls.join(', ')}. Total : #{rolls.inject(:+)}"
    else
      return "1 #{target}-sided Die: #{Random.rand(1..target.to_i)}"
    end
  end
end

def sudo(target, user)
  return '' unless user.can('sudo')
  if target.tainted? 
    return 'Tainted input.'
  else
    begin
      return eval(target)
    rescue
      return "Error: I can not $sudo #{target}"
    end
  end
end

def last(target, user)
  return '' unless user.can('last')
  begin
    return "Last message of #{target} was \"#{ShowdownBot.messages[target][1][0]}\" at #{Time.at(ShowdownBot.messages[target][0].to_i)}."
  rescue
    return "I can't remember #{target}'s last message."
  end
end

def rank(target, user)
  return '' unless user.can('rank')
  if !can('rank', user) then return '' end
  if ($ranks[command].nil?) then command_rank = 'unranked' else command_rank = $ranks[command] end
  return "The current rank for #{command} is #{command_rank}."
end

def google(target, user)
  return '' unless user.can('google')
  url = "http://www.google.com/search?q=#{CGI.escape(target)}"
  data = Nokogiri::HTML(open(url)).at('h3.r')
  data_string = data.at('./following::div').children.first.text.gsub(/(CachedSimilar|Cached)/,'')
  text = data.text
  return "#{text} | #{data_string}"
end

def salt(target, user)
  return '' unless user.can('salt')
  return "#{target} is #{(Random.rand(0.0..100.0)).round(2)}% salty."
end

def reload(target, user)
  return '' unless user.can('reload')
  begin
    load './commands.rb'
    return "Commands reloaded."
  rescue
    return "Error."
  end
end

def fight(target, user)
  return '' unless user.can('fight')
  target = target.split(',')
  person1 = target[0]
  person2 = target[1]
  if Random.rand(0..1) == 1 then userpicked = person1 else userpicked = person2 end
  message = "Hmm, if #{person1} and #{person2} were to fight, #{userpicked} would have a #{Random.rand(0..100)}% chance of winning."
  return message
end

def rank(target, user)
  return '' unless user.can('rank')
  begin
    return "The command #{target} is set to: #{$ranks[target]}"
  rescue
    return "The command #{target} is set to: unranked."
  end
end

def set(target, user)
  return '' unless user.can('set')
  target = target.gsub(/ /,'').split(',')
  command = target[0]
  rank = target[1]
  ranks = ['unranked','+','%','@','#','&','~','off','']
  if (!ranks.include? rank) then return "Have to be one of the following ranks: #{settableranks.join(', ')}" end
  $ranks[command] = rank
  File.open('ranks.yaml','w') { |b| b.write($ranks.to_yaml)}
  return "The command #{command} is now set to #{rank}."
end

def about(target, user)
  return "**BlizzyBot** : made by BlizzardQ. Made with Ruby #{RUBY_VERSION}"
end

def helix(target, user)
  return '' unless user.can('set')
  return File.readlines('data/helix.txt').sample
end

def pick(target, user)
  return '' unless user.can('pick')
  randompick = target.split(',').sample
  return "Hmm, I randomly picked #{randompick}."
end

#def dex(target=nil, user)
# return '' unless user.can('dex')
#  if target.nil?
#    target = File.readlines('data/pokemon.txt').sample.strip
#  end
  #begin
#  url = Nokogiri::HTML(open("http://bulbapedia.bulbagarden.net/wiki/#{target.capitalize}_(Pokemon)"))
#  egg = url.css('a[href="/wiki/Species"]')[0].content
#  flavor_text = url.css('td[class="roundy" and vertical-align="center"]')
#  print "FLAVOR IS #{flavor_text}"
  #return "#{target.capitalize}, the #{egg}. #{flavor_text}"
  #rescue
   # return "Seems like there is no Pokemon named #{target.capitalize}."
  #end
#end

def urban(target=nil, user)
  return '' unless user.can('urban')
  if target.nil?
    url = "http://api.urbandictionary.com/v0/random"
  else
    if target.include? ' '
      target = target.split(' ').join('+')
    end
    url = "http://api.urbandictionary.com/v0/define?term=#{target}"
  end
  urban = JSON.parse(RestClient.get url)
  return "#{urban['list'][0]['word']}: #{urban['list'][0]['definition'].gsub(/[\[\]\n]/,'')}"
end

def echo(target, user)
  return '' unless user.can('echo')
  if ((target.include? '/transferbucks' or target.include? '/tb') and (!user.match(/#{$owner}/i)))
    return ""
  else
    return target
  end
end

def define(target, user)
  return '' unless user.can('define')
  begin
    if target == 'dead'
      return "dead: Gold's server."
    end
    dictionary = Nokogiri::HTML(open("http://www.dictionary.reference.com/browse/#{target.downcase}"))
    return "#{target}: #{dictionary.css('.def-content')[0].content.strip}"
  rescue
    return "#{target} is not a word."
  end
end

