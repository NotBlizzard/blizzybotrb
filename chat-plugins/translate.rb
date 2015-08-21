require_relative '../plugins.rb'
require 'byebug'
require 'faraday'



class Translate
  extend Plugin
  match_string "#{YAML.load_file('options.yaml')['user']}, translate (.+) from (.+) to (.+)"

  def initialize
    @key = YAML.load_file("options.yaml")['key']
  end

  def do(message)
    messages = message.split('|')
    if messages[1] == 'c:' and $start_time < messages[2].to_i
      msg = messages[4].split('translate ')[1].split(' from')[0]
      from = messages[4].split('from ')[1].split(' ')[0]
      to = messages[4].split('to ')[1]
      data = JSON.parse(Faraday.get("https://translate.yandex.net/api/v1.5/tr.json/translate?key=#{@key}&lang=#{from}-#{to}&text=#{CGI.escape(msg)}").body)

      if data['text'][0] == data['text'][0].upcase
        return "I couldn't translate that."
      end

      data['text'][0]
    end
  end
end