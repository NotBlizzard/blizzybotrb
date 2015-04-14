require 'json'
require 'yaml'

RANKS = JSON.parse(File.read('ranks.json'))
OWNER = YAML.load_file('options.yaml')['owner']

class Array
  def englishize
    if self.length == 2
      return self.join(' and ')
    else
      last_element = self.last
      new_arr = self - Array(last_element)
      str = new_arr.join(', ')
      return "#{str}, and #{last_element}"
    end
  end
end

class String
  def can(cmd)
    return true if self =~ /\W\s*#{OWNER}/i
    groups = {
        ' ' => 0,
        '+' => 1,
        '%' => 2,
        '@' => 3,
        '#' => 4,
        '&' => 4,
        '~' => 5,
        'off' => 6
    }
    rank = self[0]
    return true unless (RANKS.include? command) || (groups[RANKS[cmd]] == ' ')
    rank = ' ' unless groups.keys.include? rank
    groups[rank] >= groups[RANKS[cmd]]
  end
end