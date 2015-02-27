require 'rest_client'
require 'nokogiri'
require 'open-uri'

require 'cgi'

require './parser.rb'
require './helpers.rb'

unless File.exist?('config/ranks.json')
  File.open('config/ranks.json', 'w') { |f| f.write('{}') }
end

RANKS = JSON.parse(File.read('config/RANKS.json'))

def slap(target = nil, user)
  return '' unless user.can('slap')
  "/me slaps #{target} with a fish."
end

def exit(_, user)
  return '' unless user.can('exit')
  ShowdownBot.exit
end

def dice(target = nil, user)
  return '' unless user.can('dice')
  if target.nil?
    return "1 6-sided Die: #{Random.rand(1..6)}"
  else
    if target.include? 'd'
      target  =  target.to_s.split('d')
      dice  =  target[0].to_i
      range  =  target[1].to_i
      if dice > 20
        return 'Too many dice.'
      elsif range > 99
        return "Range can't be over 99."
      end
      rolls  =  []
      dice.times do
        rolls << Random.rand(1..range.to_i)
      end
      return "#{dice} #{range}-sided Dice: #{rolls.join(', ')}.
              Total : #{rolls.inject(:+)}"
    else
      return "1 #{target}-sided Die: #{Random.rand(1..target.to_i)}"
    end
  end
end

def whois(target, user)
  return '' unless user.can('whois')
  return '' if target.nil?
  adj  =  File.readlines('data/adjectives.txt').sample.strip
  noun  =  File.readlines('data/nouns.txt').sample.strip
  "#{target} is a(n) #{adj} #{noun}."
end

def sudo(target, user)
  return '' unless user.can('sudo')
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
  command_rank  =  RANKS[target] || 'unranked'
  "The rank for #{target} is: #{command_rank}"
end

def google(target, user)
  return '' unless user.can('google')
  url  =  "http://www.google.com/search?q = #{CGI.escape(target)}"
  data  =  Nokogiri::HTML(open(url)).at('h3.r')
  data_string = data.at('./following::div').children.first.text
  data_string.gsub!(/(CachedSimilar|Cached)/, '')
  text  =  data.text
  "#{text} | #{data_string}"
end

def salt(target, user)
  return '' unless user.can('salt')
  "#{target} is #{(Random.rand(0.0..100.0)).round(2)}% salty."
end

def reload(_, user)
  return '' unless user.can('reload')
  begin
    load './commands.rb'
    'Commands reloaded.'
  rescue
    return 'Error.'
  end
end

def fight(target, user)
  return '' unless user.can('fight')
  target  =  target.split(',')
  if target.length > 2
    nums = []
    (target.length.to_i - 1).times.reduce([]) do |a|
      max  =  100 - a.inject(:+).to_i
      nums << Random.rand(0..max)
    end
    nums << 100 - nums.inject(:+)
    message = "If #{target.englishize} were to fight, #{target.sample} would have the best chance of winning with #{nums.max}%."
  else
    message = "If #{target[0]} and #{target[1]} were to fight, #{target.sample} would have a #{Random.rand(0..100)}% chance of winning."
  end
  message
end

def set(target, user)
  return '' unless user.can('set')
  target  =  target.gsub(/ /, '').split(',')
  command  =  target[0]
  rank  =  target[1]
  RANKS[command]  =  rank
  File.open('config/RANKS.json ', 'w') { |b| b.write(RANKS.to_json) }
  "The command #{command} is now set to #{rank}."
end

def about(_, _)
  "**BlizzyBot** : made by BlizzardQ. Made with Ruby #{RUBY_VERSION}."
end

def helix(_, user)
  return '' unless user.can('set')
  File.readlines('data/helix.txt').sample
end

def pick(target, user)
  return '' unless user.can('pick')
  randompick = target.split(',').sample
  "Hmm, I randomly picked #{randompick}."
end

def urban(target = nil, user)
  return '' unless user.can('urban')
  url = 'http://api.urbandictionary.com/v0/random' if target.nil?
  target = target.split(' ').join('+') if target.include? ' '
  url = "http://api.urbandictionary.com/v0/define?term = #{target}"
  urban = JSON.parse(RestClient.get url)
  "#{urban['list'][0]['word']}: #{urban['list'][0]['definition'].gsub(/[\[\]\n]/, '')}"
end

def echo(target, user)
  return '' unless user.can('echo')
  target
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

