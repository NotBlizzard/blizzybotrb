require 'rest_client'
require 'open-uri'
require 'rubygems'
require 'hyoka'
require 'time-lord'
require 'time_diff'
require 'byebug'
require 'cgi'

require './chat-parser.rb'
require './helpers.rb'

unless File.exist?('ranks.json')
  File.open('ranks.json', 'w') { |f| f.write('{}') }
end

module Commands
  HYOKA = Hyoka.new
  ROOT = File.dirname(File.absolute_path(__FILE__))
  RANKS = {
    ' ' => 0,
    '+' => 1,
    '%' => 2,
    '@' => 3,
    '&' => 4,
    '~' => 5
  }

  def uptime(args, room, user)
    return '' unless user.can('uptime')
    # Hackish way is hackish.
    self.say(room, "Uptime is currently #{(Time.now.to_i - $start_time).ago.to_words.to_s.split(' ago')[0]}")
  end

  def slap(args, room, user)
    return '' unless user.can('slap')
    self.say(room, "/me slaps #{args} with a fish.")
  end

  def seen(args, room, user)
    return '' unless user.can('seen')
    args = args.downcase.gsub(/[^a-z0-9]/,'')
    if user.gsub(/[^a-z0-9]/) == args
      return self.say(room, "Look in the mirror.")
    end
    if $seen_data.keys.include? args
      self.say(room, "#{args} was last seen about #{(Time.now.to_i - $seen_data[args].seconds).ago.to_words}")
    else
      self.say(room, "#{args} has never been seen before.")
    end
  end

  def unscramble(args, room, user)
    pokemon = File.read(ROOT + '/data/pokemon.txt').lines.map{|x| x.delete!("\n") }
    correct_pokemon = ''
    pokemon.each do |pokemon|
      if pokemon.chars.sort.join == args.chars.sort.join
        correct_pokemon = pokemon
      end
    end
    "#{correct_pokemon}"
  end

  def ladder(args, room, user)
    return '' unless user.can('ladder')
    if ($ladder)
      $ladder = false
      self.say(room, "Laddering is now off.")
    else
      $ladder = true
      if TIERS.include? args
        $ladder_tier = args
        @ws.send("#{room}|/search #{args}")
        self.say(room, "I am now laddering.")
      else
        self.say(room, "not a valid tier.")
      end
    end
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
    if arg.nil? or arg.length == 0
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

  def >(args, room, user)
    return '' unless user.can('eval')
    begin
      self.say(room, "#{eval(args)}")
    rescue
      self.say(room, "Error.")
    end
  end

  def a(a, r, u)
    self.say(room, "#{eval(a)}")
  end

   def py(args, room, user)
    self.say(room, "> #{HYOKA.eval('print('+args+')', 'python/cpython-3.4.1')}")
  end

  def rb(args, room, user)
    self.say(room, "> #{HYOKA.eval('puts '+args, 'ruby/mri-2.2')}")
  end

  def js(args, room, user)
    self.say(room, "> #{HYOKA.eval('console.log('+args+')', 'javascript/node-0.10.29')}")
  end

  def php(args, room, user)
    self.say(room, "> #{HYOKA.eval('<?php echo'+args+' ?>', 'php/php-5.5.14')}")
  end

  def rank(args, room, user)
    return '' unless user.can('rank')
    command_rank  =  RANKS[args] || 'unranked'
    self.say(room, "The rank for #{args} is: #{command_rank}")
  end

  def salt(args, user)
    return '' unless user.can('salt')
    "#{args} is #{(Random.rand(0.0..100.0)).round(2)}% salty."
  end

  def hotpatch(args, room, user)
    return '' unless user.can('reload')
    begin
      case args
      when 'plugins'
        Dir[ROOT + '/chat-plugins/*.rb'].each {|file| load file }
        self.say(room, "#{args} reloaded.")
      when 'commands'
        load './commands.rb'
        self.say(room, "#{args} reloaded.")
      when 'helpers'
        load './helpers.rb'
        self.say(room, "#{args} reloaded.")
      when 'battles'
        load './battle.rb'
        load './battle-helpers.rb'
        load './battle-parser.rb'
        self.say(room, "#{args} reloaded.")
      when 'chat'
        load './chat-parser.rb'
        load './chat-helpers.rb'
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
    return '' unless user.can('echo')
    args
  end
end

