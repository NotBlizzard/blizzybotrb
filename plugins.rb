# Here we define plugins for the bot. This is different from commands.

module Plugin
  attr_accessor :classes, :match

  def match_string str
    @match = Regexp.new str
  end

   def self.extended(base)
    @classes =  @classes || []
    @classes << base.name
  end

  def self.classes
    @classes
  end
end

