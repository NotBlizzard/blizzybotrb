require_relative '../plugins.rb'

require 'faraday'
require 'cleverbot-api'

class Cleverbot
  extend Plugin


    match_string "blizzybot"

  def initialize
      $bot = CleverBot.new
  end

  def do(message)
    messages = message.split('|')
    msg = messages[4]
    $bot.think msg
  end
end

