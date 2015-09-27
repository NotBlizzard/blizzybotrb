require_relative '../plugins.rb'
require 'byebug'


class Obama
  extend Plugin

  match_string /thanks, obama/i

  def do(message)
   "You're Welcome."
 end
end