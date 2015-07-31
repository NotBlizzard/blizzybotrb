require_relative '../plugins.rb'
require 'byebug'
require 'faraday'



class Translate
  extend Plugin
  match_string "#{YAML.load_file('options.yaml')['user']}, translate (.+) from (.+) to (.+)"

  def do(message)
    messages = message.split('|')
    if messages[1] == 'c:' and $start_time < messages[2].to_i
      msg = messages[4].split('translate ')[1].split(' from')[0]
      from = messages[4].split('from ')[1].split(' ')[0]
      to = messages[4].split('to ')[1]
      data = JSON.parse(Faraday.get("http://api.mymemory.translated.net/get?q=#{msg}&langpair=#{from}|#{to}").body)

      if data['responseData']['translatedText'] == data['responseData']['translatedText'].upcase
        return "I couldn't translate that."
      end

      data['responseData']['translatedText']
    end
  end
end