vim9script

def Partition(items: number, parts: number): list<number>
  const min_amount = items / parts
  const remainder = items % parts
  var partitions = []
  for i in range(parts)
    var amount = min_amount + (i < remainder ? 1 : 0)
    add(partitions, amount)
  endfor
  return partitions
enddef


class Partitioner
  this.total_width: number
  this.explorer_width: number
  this.min_window_width: number

  def MaxParts(): number
    const max_parts = this.total_width / this.min_window_width
    if this.total_width % this.min_window_width >= max_parts - 1
      return max_parts
    endif
    return max_parts - 1
  enddef

  def Partition(has_explorer: bool, parts: number): list<number>
    var partition = []
    var remainder = this.total_width - (parts - 1)
    if has_explorer
      partition = [this.explorer_width]
      remainder -= (this.explorer_width + 1)
    endif
    return partition + Partition(remainder, parts)
  enddef
endclass
