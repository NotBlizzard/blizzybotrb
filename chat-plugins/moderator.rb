require_relative '../plugins.rb'

class Moderator
  extend Plugin

  match_string /\W/

  attr_accessor :users

  FLOOD_TIME = 5000
  FLOOD_NUM = 5
  @@users = Hash.new{|k,v| k[v] = 0}
  @@users_message_handler = Hash.new{|k,v| k[v] = Hash.new{|k,v| k[v] = 0}}

  def initialize
    @warn_levels = {
      0 => 'warn',
      1 => 'warn',
      2 => 'warn',
      3 => 'mute',
      4 => 'mute',
      5 => 'hourmute'
    }

  end

  def do(message)
    messages = message.split('|')
    msg = ''
    if messages[1] == 'c:'
      user = messages[3].downcase.gsub(/[^a-z0-9]/,'')

       @@users_message_handler[user][:messages] +=1
       @@users_message_handler[user][:time] = messages[2].to_i

      if messages[4] =~ /(.)\1{7}/
        msg = "#{@warn_levels[@@users[user]]} #{user}, stretching"
        @@users[user]+=1
      end

      if messages[4] =~ /[A-Z]{12}/
        msg = "#{@warn_levels[@@users[user]]} #{user}, caps"
        @@users[user]+=1
      end

      if Time.now.to_i - @@users_message_handler[user][:time] > FLOOD_TIME
        @@users_message_handler[user][:messages] = 0
      end

      if @@users_message_handler[user][:messages] > FLOOD_NUM and Time.now.to_i - @@users_message_handler[user][:time] < FLOOD_TIME
        msg = "flooding m8"
      end

      if @@users[user] > 5
        msg = "roomban #{user}, troubled user"
      end

      msg
    end
  end
end