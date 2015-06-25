require 'rest_client'
require 'open-uri'
require 'rubygems'
require 'hyoka'

require 'cgi'

require './parser.rb'
require './helpers.rb'

unless File.exist?('ranks.json')
  File.open('ranks.json', 'w') { |f| f.write('{}') }
end

module Commands
  def slap(args, room, user)
    return '' unless user.can('slap')
    self.say(room, "/me slaps #{args} with a fish.")
  end

  def l(args, room, user)
    return '' unless user.can('ladder')
    if ($ladder)
      $ladder = false
      self.say(room, "Laddering is now off.")
    else
      $ladder = true
      @ws.send("#{room}|/search challengecup1v1")
      self.say(room, "I am now laddering.")
    end
  end

  def remind(args, room, user)
    Thread.new {
      sleep(args)
      #self.say(room, "Hello")
      puts "OK"
    }.join
  end

  def talk(args, room, user)
    return '' unless user.can('sudo')
    unless ($talk)
      $talk = true
      self.say(room, "Talking is now on")
    else
      $talk = false
      self.say(room, "Talking is now off")
    end
  end

  def flip(arg, room, _)
    if arg.nil?
      self.say(room,"(╯°□°）╯︵ ┻━┻")
    else
      self.say(room,"(╯°□°）╯︵ #{arg.flip}")
    end
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

  def irb(args, room, user)
    #return '' unless user.can('eval')
    self.say(room, "#{eval(args)}")
  end

  def a(a, r, u)
    self.say(room, "#{eval(a)}")
  end

  def sudo(args, room, user)
    data = args.split(', ')[0]
    language = args.split(', ')[1]
    h = Hyoka.new
    case language
    when 'py'
      self.say(room, "> #{h.eval data, 'python/cpython-2.7.8'}")
    when 'rb'
      self.say(room, "> #{h.eval data, 'ruby/mri-2.1'}")
    when 'js'
      self.say(room, "> #{h.eval data, 'javascript/node-0.10.29'}")
    when 'php'
      self.say(room, "> #{h.eval data, 'php/php-5.5.14'}")
    end
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

  def hotpatch(args, room, user)
    return '' unless user.can('reload')
    begin
      case args
      when 'commands'
        load './commands.rb'
        self.say(room, "#{args} reloaded.")
      when 'helpers'
        load './helpers.rb'
        self.say(room, "#{args} reloaded.")
      when 'battles'
        load './battle.rb'
        self.say(room, "#{args} reloaded.")
      when 'parser'
        load './parser.rb'
        self.say(room, "#{args} reloaded.")
      else
        self.say(room, "#{args} is not recognized as a hotpatch.")
      end
    rescue
      self.say(room, 'Error.')
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
    if rank == 'u'
      rank = ' '
    end
    RANKS[command] = rank
    File.open('ranks.json', 'w') { |b| b.write(RANKS.to_json) }
    self.say(room, "The command #{command} is now set to #{rank}.")
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
    if user.downcase.include? "terlor"
      return "no"
    end
    return '' unless user.can('echo')
    args
  end

  #def define(args, room, user)
  #  return '' unless user.can('define')
  #  begin
  #    dictionary = Nokogiri::HTML(open("http://www.dictionary.reference.com/browse/#{args.downcase}"))
  #    return "#{args}: #{dictionary.css('.def-content')[0].content.strip}"
  #  rescue
   #   return "#{args} is not a word."
   # end
  # end
end

