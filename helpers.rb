require 'json'
require 'yaml'

$ranks = JSON.parse(File.read('config/ranks.json'))
$owner = YAML.load_file('config/options.yaml')['owner']

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
  def can(command)
    if self =~ /\W\s*#{$owner}/i then return true end

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
    if (!$ranks.include? command or groups[$ranks[command]] == ' ') then return true end
    if (!groups.keys.include? rank) then rank = ' ' end
    return groups[rank] >= groups[$ranks[command]]
  end
end