# app.rb - Where the script runs.
require 'rubygems'
require 'bundler/setup'

ROOT = File.dirname(File.absolute_path(__FILE__))
Dir[ROOT + '/plugins/*.rb'].each { |file| require file }

require './bot'
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
  Bot.new(
    options['user'],
    options['pass'],
    options['rooms'],
    options['server'],
    options['admins'],
    options['symbol'],
    [Gfycat, What]
  ).connect
end
