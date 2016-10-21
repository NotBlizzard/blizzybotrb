
require 'faye/websocket'
require 'open-uri'
require 'rest-client'
require 'json'
require 'time'
require 'byebug'

require './commands.rb'
require './battle/battle.rb'

# Main file for the Pokemon Showdown bot.
class Bot
  include Commands
  attr_accessor :ws, :room, :user, :rooms, :server,
                :admins, :symbol, :log, :plugins, :battles, :rooms_joined

  def initialize(user, pass, rooms, server, admins, symbol, plugins)
    @accepting_battles = true
    @last_message = nil
    @rooms_enumerator = rooms.to_enum
    @rooms_joined = []
    @commands = []
    @plugins = plugins
    @battles = []
    @symbol = symbol
    @admins = admins
    @teams = JSON.parse(File.read('./data/pokemon_teams.json'))
    @rooms = rooms
    @user = user
    @pass = pass
    @ws = Faye::WebSocket::Client.new("ws://#{server}/showdown/websocket")
  end

  def to_s
    "<Bot: username:#{@user}>"
  end

  def current_battle
    @battles.select { |i| i.value.room == @room }[0].value
  end

  def challstr(message)
    url = 'http://play.pokemonshowdown.com/action.php'

    if @pass.nil?
      data = {
        'act' => 'getassertion',
        'userid' => @user,
        'challengekeyid' => message[2],
        'challenge' => message[3]
      }
      @ws.send("|/trn #{@user},0,#{RestClient.get(url, data).body}")
    else
      data = {
        'act' => 'login',
        'name' => @user,
        'pass' => @pass,
        'challengekeyid' => message[2],
        'challenge' => message[3]
      }
      data = RestClient.post url, data
      @ws.send("|/trn #{@user},0,#{JSON.parse(data[1..-1])['assertion']}")
    end
  end

  def plugin(plugin, message, last_message, room, user)
    @commands << Thread.new { @ws.send("#{@room}|#{plugin.new.do(message, last_message, room, user)}") }.join
  end

  def command(message, room, user)
    command = message[/\w+/]
    args = !message[/ /].nil? ? message.split(/\$\w+ /)[1] : []
    @commands << Thread.new { @ws.send("#{@room}|#{send(command, args, room, user, self)}") }.join
  end

  def message(messages, battle = false)
    i = battle ? 3 : 4
    plugin = @plugins.select { |z| !messages[i].match(z.match).nil? }[0]

    if (messages[i-1] =~ Regexp.compile(@user)).nil? || (messages[i-1] =~ Regexp.compile(@user)) < 0
      if !plugins.nil? and @rooms_joined.include? @room
        plugin(plugin, messages[i], @last_message, @room, messages[i-1])
      end

      if messages[i][0] == @symbol and @rooms_joined.include? @room and (messages[i-1] =~ Regexp.compile(@user)) != 1
        command(messages[i], @room, messages[i-1])
      end
    end
  end




  def send_command(command, args, room, user)
    begin
      @ws.send("#{room}|#{send(command, args, room, user, self)}")
    rescue => e
      @ws.send("#{room}|Seems like the command failed.")
      puts e.message
      puts e.backtrace.join("\n")
    end
  end

  def request(messages)
    unless @battles.any? { |i| i.keys.include? @room }
      battle_tier = @room.split('-')[1]
      @battles << Thread.new { Battle.new(@ws, battle_tier, @room, self) }.join
      @battles.last.value.send('update_team', messages[2])
      @battles.last.value.send('battle', messages)
      @rooms_joined << @room
    end
  end

  def battle(i, battle_tier, who)
    if i
      if %w(randombattle ou).include? battle_tier
        battle_team = @teams[battle_tier]
        @ws.send("|/utm #{battle_team}") unless battle_tier.include? 'random'
        @ws.send("|/accept #{who}")
      end
    else
      @ws.send("|/pm #{who}, I am not accepting battles at the moment.")
      @ws.send("|/reject #{who}")
    end
  end

  def updatechallenges(messages)
    data = JSON.parse(messages[2])['challengesFrom']
    unless data.keys.empty?
      battle(@accepting_battles, data[data.keys[0]], data.keys[0])
    end
  end

  def updateuser(messages)
    unless messages[2].include? "Guest"
      @rooms.each { |room| @ws.send("|/join #{room}") }
    end
  end

  def raw(messages)
    if messages[2].include? "infobox"
      room = @rooms_enumerator.next
      puts "room is #{room}"
      @rooms_joined << room unless @rooms_joined.include? room
    end
  end

  def update_room(data)
    @room = data[0] == '>' ? data[1..-1].gsub('\n', '').gsub("\n", '') : @room
  end

  def update_battles(messages)
    begin
      @battles.each do |battle|
        battle.value.send('battle', messages) if battle.value.room == @room
      end
    rescue => e
      puts e.message
    end
  end

  def messages(messages)
    case messages[1]
    when 'c:'
      message(messages)
    when 'c'
      message(messages, true)
    else
      begin
        send(messages[1], messages)
      rescue
      end
    end
  end

  def connect
    @ws.on :message do |event|
      event.data.split("\n").each do |message|
        update_room(message)
        puts message
        update_battles(message.split('|'))
        messages(message.split('|'))
        @last_message = message if message[0] != ">"
      end
    end
  end
end
