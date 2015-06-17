require 'json'
require 'yaml'

$ranks = JSON.parse(File.read('ranks.json'))
$owner = YAML.load_file('options.yaml')['owner']

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

  def flip
    self.downcase.tr!('a-z','ɐqɔpǝɟƃɥᴉɾʞlɯuodbɹsʇnʌʍxʎz').reverse
  end

  def can(cmd)
    return true if self =~ /(?<=^.)(.*)/i
    groups = {
        'u' => 0,
        '+' => 1,
        '%' => 2,
        '@' => 3,
        '#' => 4,
        '&' => 4,
        '~' => 5,
        'off' => 6
    }
    r = self[0]
    if not groups.keys.include? r
      r = 'u'
    end
    return groups[r] >= groups[$ranks[cmd]]

  end
end