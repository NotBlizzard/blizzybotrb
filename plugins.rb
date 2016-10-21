# Here we define plugins for the bot. This is different from commands.


class Plugin
  attr_accessor :match
  @match = ''

  def self.match
    @match
  end
end
