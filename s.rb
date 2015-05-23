require 'rest-client'

url = "http://play.pokemonshowdown.com/crossdomain.php?host=#{ARGV.first}&path="
data = JSON.parse((RestClient.get url).split('var config = ')[1].split(';')[0])
puts "Host: #{data['host']}"
puts "Port: #{data['port']}"