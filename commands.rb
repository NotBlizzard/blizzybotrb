require 'rest_client'
require 'nokogiri'
require 'open-uri'
require 'json'
require 'yaml'
require 'cgi'

require './parser.rb'

if !File.exist?('config/ranks.json')
  File.open('config/ranks.json','w') {|f| f.write("{}") }
end

$ranks = JSON.parse(File.read('config/ranks.json'))
$owner = YAML.load_file('config/options.yaml')['owner']


class String

  def can(command)
    if self =~ /\W\s*#{$owner}/i then return true end

    groups = {
        ' ' => 0,
        '+' => 1,
        '%' => 2,
        '@' => 3,
        '#' => 4,
        '&' => 4,
        '~' => 5,
        'off' => 6
    }
    rank = self[0]
    if (!$ranks.include? command or groups[$ranks[command]] == ' ') then return true end
    if (!groups.keys.include? rank) then rank = ' ' end
    return groups[rank] >= groups[$ranks[command]]
  end
end

def slap(target=nil, user)
  return '' unless user.can('slap')
  return "/me slaps #{target} with a fish."
end

def exit(target=nil, user)
  return '' unless user.can('exit')
  ShowdownBot.exit
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
  #return '' unless user.can('sudo')
  if target.tainted?
    return 'Tainted input.'
  else
    begin
      return eval(target)
    rescue
      return "Error: I can not sudo #{target}"
    end
  end
end

def rank(target, user)
  return '' unless user.can('rank')
  command_rank = $ranks[target] || "unranked"
  return "The rank for #{target} is: #{command_rank}"
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
  #return '' unless user.can('reload')
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
  message = "If #{person1} and #{person2} were to fight, #{userpicked} would have a #{Random.rand(0..100)}% chance of winning."
  return message
end

def set(target, user)
  return '' unless user.can('set')
  target = target.gsub(/ /,'').split(',')
  command = target[0]
  rank = target[1]
  $ranks[command] = rank
  File.open('config/ranks.json','w') {|b| b.write($ranks.to_json)}
  return "The command #{command} is now set to #{rank}."
end

def about(target, user)
  return "**BlizzyBot** : made by BlizzardQ. Made with Ruby #{RUBY_VERSION}."
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
  return target
end

def define(target, user)
  return '' unless user.can('define')
  begin
    dictionary = Nokogiri::HTML(open("http://www.dictionary.reference.com/browse/#{target.downcase}"))
    return "#{target}: #{dictionary.css('.def-content')[0].content.strip}"
  rescue
    return "#{target} is not a word."
  end
end

