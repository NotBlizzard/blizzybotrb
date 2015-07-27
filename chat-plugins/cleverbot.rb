require_relative '../plugins.rb'

require 'faraday'
require 'cleverbot-api'

class Cleverbot
  extend Plugin

  match_string "blizzybot"

  def initialize
    @clever_bot = CleverBot.new
  end

  def do(message)
    messages = message.split('|')
    msg = messages[4]
    @clever_bot.think msg
  end
end

