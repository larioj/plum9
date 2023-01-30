vim9script

class SplitList
  this.members: list<number>
  this.split_locations: list<number>

  def Sizes(): list<number>
    var result = copy(this.split_locations) + [len(this.members) - 1]
    var prev = 0
    for i in range(len(result))
      result[i] += 1 - prev
      prev += result[i]
    endfor
    return result
  enddef 

  def ToStr(): string
    var members: list<any> = copy(this.members)
    for i in range(len(this.split_locations))
      const sl = this.split_locations[i]
      insert(members, '|', sl + 1 + i)
    endfor
    return join(members, ' ')
  enddef
endclass

def MoveMember(split_list: SplitList, split: number, direction: number): SplitList
  var members = split_list.members
  var split_locations = copy(split_list.split_locations)
  split_locations[split] -= direction
  return SplitList.new(members, split_locations)
enddef


def Percolate(direction: number, split_list: SplitList, region: number, split_deltas: list<number>)


enddef

export def g:SplitListTests()
  echo SplitList.new([0, 0, 0], [1]).ToStr()
  echo SplitList.new([1, 2, 3], [0, 1]).ToStr()
  echo SplitList.new([1, 2, 3], [0, 0]).ToStr()
  echo MoveMember(SplitList.new([1, 2, 3, 4, 7, 6, 7, 8, 9], [2, 5]), 1, 1).ToStr()
  echo MoveMember(SplitList.new([1, 2, 3, 4, 7, 6, 7, 8, 9], [2, 5]), 1, 1).ToStr()
  echo MoveMember(SplitList.new([1, 2, 3, 4, 7, 6, 7, 8, 9], [2, 5]), 1, 1).Sizes()
enddef
