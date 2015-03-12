require 'rubygems'
require 'bundler/setup'

require './parser.rb'
require 'eventmachine'
require 'yaml'

begin
  options = YAML.load_file('options.yaml')
rescue
  puts "You need to rename 'options-example.yaml' to 'options.yaml'\n
        in /config and add your credentials."
  exit!
end

EventMachine.run do
  ShowdownBot.new(
    options['user'],
    options['pass'],
    options['rooms'],
    options['server'],
    options['owner'],
    options['symbol'],
    options['log']
  ).run
end
