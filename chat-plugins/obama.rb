require_relative '../plugins.rb'

class Obama
  extend Plugin

  match_string /thanks, obama/i

  def do(message)
   "You're Welcome."
 end
end