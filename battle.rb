TYPE_NUM = {
  :normal => 1,
  :fight => 2,
  :flying => 3,
  :poison => 4,
  :ground => 5,
  :rock => 6,
  :bug => 7,
  :ghost => 8,
  :steel => 9,
  :fire => 10,
  :water => 11,
  :grass => 12,
  :electric => 13,
  :psychic => 14,
  :ice => 15,
  :dragon => 16,
  :dark => 17,
  :fairy => 18
}
WEAKNESS_URL = "https://gist.githubusercontent.com/NotBlizzard/f2e72ad079b6a211c2b0/raw/a734064c23cea6027f9c720afdc6376c8e6ee9e5/weaknesses.json"
POKEDEX_URL = "https://gist.githubusercontent.com/NotBlizzard/a84ad1737c801f748b01/raw/69dc8756a924aa846a4673c591ebf37a0fc60980/pokedex.json"
SUPER_EFFECTIVENESS_URL = "https://gist.githubusercontent.com/NotBlizzard/dede16ec50b4d4693b2d/raw/1e117b0ffb98ba0fa47d6b5f0da9d52a537266ae/supereffectiveness.json"
RESISTANCE_URL = "https://gist.githubusercontent.com/NotBlizzard/cc46e43ac6df8e87e1f9/raw/84e8164a2a92bed7ca81fc7df503209975a1fef6/resistances.json"

require 'rest-client'
def decide(moves, you, opponent)
  return 4
  moves_power = []
  you_type = JSON.parse(RestClient.get(POKEDEX_URL))['types']
  moves.each do |move|
    mod = 1
    move[:type].each do |type|
      if you_type.include? type
        mod = 1.5
      end
    end
    moves_power << move[:power] * mod
  end
  highest = moves_power.sort.reverse[0]
  move_index = moves_power.index(highest)
  #return moves[move_index][:name]
  #opponent_weaknesses = Array.new
  #opponent_resistances = Array.new
  #move_1_adv = JSON.parse(RestClient.get(SUPER_EFFECTIVENESS_URL))[moves[0][:type]].to_a
  #move_2_adv = JSON.parse(RestClient.get(SUPER_EFFECTIVENESS_URL))[moves[1][:type]].to_a
  #move_3_adv = JSON.parse(RestClient.get(SUPER_EFFECTIVENESS_URL))[moves[2][:type]].to_a
  #move_4_adv = JSON.parse(RestClient.get(SUPER_EFFECTIVENESS_URL))[moves[3][:type]].to_a
  #opponent_type = JSON.parse(RestClient.get(POKEDEX_URL))[opponent.downcase]['types'].to_a
  #opponent_type.each do |p|
  #  opponent_weaknesses << JSON.parse(RestClient.get(WEAKNESS_URL))[p.downcase].to_a
  #  opponent_resistances << JSON.parse(RestClient.get(RESISTANCE_URL))[p.downcase].to_a
  #end
  #opponent_weaknesses = opponent_weaknesses.flatten
  #0.upto(3) do |i|
  #  if opponent_weaknesses.include? moves[i][:type]
  #    use << moves[i][:name]
  #  end
  #end
  #if use.empty?
  # 0.upto(3) do |i|
  #    unless opponent_resistances.include? moves[i][:type]
  #      use << moves[i][:name]
  #    end
  #  end
  #  if use.empty?
  #   # At this point, it can't find a super effective nor normal move. RIP.
  #    return moves.keys.sample
  #  end
  # return use.sample
  #else
  #  return use.sample
  #end
end


