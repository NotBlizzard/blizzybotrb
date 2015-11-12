require_relative '../plugins.rb'

$seen_data = {}

class Seen
  extend Plugin

  match_string /\W/

  def do(message)
    messages = message.split('|')
    if messages[1] == 'c:' and $start_time < messages[2].to_i
      user = messages[3].downcase.gsub(/[^A-z0-9]/,'')
      $seen_data[user] = Time.now.to_i
      ''
    end
  end
end