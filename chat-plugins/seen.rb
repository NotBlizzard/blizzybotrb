require_relative '../plugins.rb'
require 'byebug'
require 'faraday'

$seen_data = {}

class Seen
  extend Plugin

  match_string /\W/

  def do(message)
    messages = message.split('|')
    if messages[1] == 'c:'
      user = messages[3].downcase.gsub(/[^A-z0-9]/,'')
      $seen_data[user] = Time.now.to_i
      ''
    end
  end
end