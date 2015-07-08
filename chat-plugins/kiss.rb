require_relative '../plugins.rb'
require 'byebug'


class Kiss
  extend Plugin

  match_string "o3o"

  def do(message)
   messages = message.split('|')
   user ||= messages[3]
   unless user =~ /\Wblizzybot/
    "o3o"
   end
 end
end