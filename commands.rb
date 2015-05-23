require 'rest_client'
require 'nokogiri'
require 'open-uri'
require 'rubygems'

require 'cgi'

require './parser.rb'
require './helpers.rb'

unless File.exist?('ranks.json')
  File.open('ranks.json', 'w') { |f| f.write('{}') }
end

# def foo(args, room, user)
#   self.say(room, "Hello")
# end

def slap(args, room, user)
  return '' unless user.can('slap')
  self.say(room, "/me slaps #{args} with a fish.")
end

def flip(_, room, _)
  self.say(room,"(╯°□°）╯︵ ┻━┻")
end

def trivia(_,room, user)
  return '' unless user.can('trivia')
  url = "http://mentalfloss.com/api/1.0/views/amazing_facts.json?limit=1"
  data = JSON.parse(RestClient.get url)
  self.say(room, data[0]['nid'].gsub(/<?(\/)p>/,'').gsub('<p>',''))
end

def exit(_,_, user)
  return '' unless user.can('exit')
  ShowdownBot.exit
end

def dice(args=nil, room, user)
  return '' unless user.can('dice')
  if args.nil?
    return "1 6-sided Die: #{Random.rand(1..6)}"
  else
    if args.include? 'd'
      args  =  args.to_s.split('d')
      dice  =  args[0].to_i
      range  =  args[1].to_i
      if dice > 20
        self.say(room, 'Too many dice.')
      elsif range > 99
        self.say(room, "Range can't be over 99.")
      end
      rolls  =  []
      dice.times do
        rolls << Random.rand(1..range.to_i)
      end
      self.say(room, "#{dice} #{range}-sided Dice: #{rolls.join(', ')}.
              Total : #{rolls.inject(:+)}")
    else
      self.say(room, "1 #{args}-sided Die: #{Random.rand(1..args.to_i)}")
    end
  end
end

def whois(args, room, user)
  return '' unless user.can('whois')
  return '' if args.nil?
  adj  =  File.readlines('data/adjectives.txt').sample.strip
  noun  =  File.readlines('data/nouns.txt').sample.strip
  self.say(room, "#{args} is a(n) #{adj} #{noun}.")
end

def ship(args, room, user)
  return '' unless user.can('ship')
  users = args.gsub(' ','').split(',').map(&:downcase)
  self.say(room, "#{users[0]} and #{users[1]}'s relationship is #{Random.rand(1..100)}% strong.")
end

def sudo(args, room, user)
  return '' unless user.can('sudo')
  self.say(room, "#{eval(args)}")
end

def rank(args, room, user)
  return '' unless user.can('rank')
  command_rank  =  RANKS[args] || 'unranked'
  self.say(room, "The rank for #{args} is: #{command_rank}")
end

#def google(args, user)
# return '' unless user.can('google')
#  url  =  "http://www.google.com/search?q=#{CGI.escape(args)}"
#  data  =  Nokogiri::HTML(open(url)).at('h3.r')
#  data_string = data.at('./following::div').children.first.text
#  data_string.gsub!(/(CachedSimilar|Cached)/, '')
#  text  =  data.text
#  "#{text} | #{data_string}"
#end

def salt(args, user)
  return '' unless user.can('salt')
  "#{args} is #{(Random.rand(0.0..100.0)).round(2)}% salty."
end

def reload(_, _, user)
  return '' unless user.can('reload')
  begin
    load './commands.rb'
    load './helpers.rb'
    'Commands reloaded.'
  rescue
    return 'Error.'
  end
end

def fight(args, user)
  return '' unless user.can('fight')
  args  =  args.split(',')
  if args.length > 2
    nums = []
    (args.length.to_i - 1).times.reduce([]) do |a|
      max  =  100 - a.inject(:+).to_i
      nums << Random.rand(0..max)
    end
    nums << 100 - nums.inject(:+)
    message = "If #{args.englishize} were to fight, #{args.sample} would have the best chance of winning with #{nums.max}%."
  else
    message = "If #{args[0]} and #{args[1]} were to fight, #{args.sample} would have a #{Random.rand(0..100)}% chance of winning."
  end
  message
end


def set(args, room, user)
  return '' unless user.can('set')
  args = args.gsub(/ /, '').split(',')
  command = args[0]
  rank = args[1]
  RANKS[command]  =  rank
  File.open('ranks.json ', 'w') { |b| b.write(RANKS.to_json) }
  "The command #{command} is now set to #{rank}."
end

def about(_,room, _)
  self.say(room, "**BlizzyBot** : made by BlizzardQ. Made with Ruby #{RUBY_VERSION}.")
end

def helix(_, room, user)
  return '' unless user.can('set')
  File.readlines('data/helix.txt').sample
end

def pick(args,room, user)
  return '' unless user.can('pick')
  randompick = args.split(',').sample
  self.class.say(room,"Hmm, I randomly picked #{randompick}.")
end

def urban(args, room, user)
  return '' unless user.can('urban')
  args = args.split(' ').join('+') if args.include? ' '
  url = "http://api.urbandictionary.com/v0/define?term=#{args}"
  url = 'http://api.urbandictionary.com/v0/random' if args.nil?
  urban = JSON.parse(RestClient.get url)
  puts '.lol.'
  "#{urban['list'][0]['word']}: #{urban['list'][0]['definition'].gsub(/[\[\]\n]/, '')}"
end

def echo(args, room, user)
  return '' unless user.can('echo')
  args
end

def define(args, room, user)
  return '' unless user.can('define')
  begin
    dictionary = Nokogiri::HTML(open("http://www.dictionary.reference.com/browse/#{args.downcase}"))
    return "#{args}: #{dictionary.css('.def-content')[0].content.strip}"
  rescue
    return "#{args} is not a word."
  end
end

