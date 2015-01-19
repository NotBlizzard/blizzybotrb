require 'rubygems'
require 'bundler/setup'

require './connect.rb'
require 'eventmachine'
require 'yaml'

begin
  options = YAML.load_file('config/options.yaml')['bots']
rescue
  puts "You need to rename 'options-example.yaml' to 'options.yaml' in config and add your credentials."
end

EventMachine.run do
  options.each do |x|
    bot = Bot.new(
      x['user'],
      x['pass'],
      x['rooms'],
      x['server'],
      x['owner'],
      x['symbol'],
      x['log']
    )
    bot.run()
  end
end