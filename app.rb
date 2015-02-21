require 'rubygems'
require 'bundler/setup'

require './parser.rb'
require 'eventmachine'
require 'yaml'


begin
  options = YAML.load_file('config/options.yaml')
rescue
  puts "You need to rename 'options-example.yaml' to 'options.yaml'\nin /config and add your credentials."
  eoptionsit!
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

