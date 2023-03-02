vim9script

import "./lib.vim"



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
    return partition + lib.Partition(remainder, parts)
  enddef
endclass


