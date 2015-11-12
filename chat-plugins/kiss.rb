require_relative '../plugins.rb'

class Kiss
  extend Plugin

  match_string "o3o"

  def do(message)
   messages = message.split('|')
   user ||= messages[3]
   unless user =~ /\Wblizzybot/i
    "o3o"
   end
 end
end