require 'rubygems'
require 'bundler/setup'

require './parser.rb'
require 'eventmachine'
require 'yaml'

begin
  options = YAML.load_file('config/options.yaml')['bots']
rescue
  puts "You need to rename 'options-example.yaml' to 'options.yaml'\nin /config and add your credentials."
  exit!
end

EventMachine.run do
  options.each do |x|
    bot = ShowdownBot.new(
      x['user'],
      x['pass'],
      x['rooms'],
      x['server'],
      x['owner'],
      x['symbol'],
      x['log'],
      x['ignore']
    )
    bot.run
  end
end