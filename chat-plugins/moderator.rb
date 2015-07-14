require_relative '../plugins.rb'
require 'byebug'


class Moderator
  extend Plugin

  match_string /\W/

  def do(message)
    messages = message.split('|')
    if messages[4] =~ /(.)\1{7}/
      "warning: stretching"
    end
  end
end