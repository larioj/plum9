vim9script

import "./lib.vim"

export class Balancer
  this.items: list<number>
  this.sizes: list<number>
  this.OnMove: func(number, number, number, number)

  def GroupItems(group: number): list<number>
    var start = 0
    for i in range(group)
      start += this.sizes[i]
    endfor
    const end = start + this.sizes[group]
    return slice(this.items, start, end)
  enddef

  def MoveFrom(group: number, direction: number)
    const dest = group + direction
    this.sizes[group] -= 1
    this.sizes[dest] += 1

    const source_items = this.GroupItems(group)
    const dest_items = this.GroupItems(dest)
    var moved = source_items[-1]
    var neighbor = dest_items[0]
    if direction == -1
      moved = source_items[0]
      neighbor = dest_items[-1]
    endif
    this.OnMove(moved, neighbor, group, dest)
  enddef

  def PercolateFrom(group: number, group_deltas: list<number>, direction: number)
    var target_group = lib.Find(group_deltas, (delta) => delta == 0, group, direction)
    while target_group != group
      var start_group = lib.Find(this.sizes, (size) => size > 1, target_group - direction, -direction)
      var cur_group = start_group
      while cur_group != target_group
        this.MoveFrom(cur_group, direction)
        cur_group += direction
      endwhile
      target_group = start_group
    endwhile
  enddef

  def BalanceAfterInsert(group: number, parent: number, child: number)
    const min_size = min(this.sizes)
    const group_deltas = mapnew(this.sizes, (_, s) => s - min_size)
    if group_deltas[group] == 0
      return
    endif
    const can_percolate_right = min(group_deltas[group : ]) == 0
    const can_percolate_left = min(group_deltas[0 : group]) == 0
    const group_items = this.GroupItems(group)
    if group_items[-1] != parent && group_items[-1] != child && can_percolate_right
      this.PercolateFrom(group, group_deltas, 1)
      this.BalanceAfterInsert(group, parent, child)
    elseif group_items[0] != parent && group_items[0] != child && can_percolate_left
      this.PercolateFrom(group, group_deltas, -1)
      this.BalanceAfterInsert(group, parent, child)
    else # we move child
      this.PercolateFrom(group, group_deltas, 1)
    endif
  enddef

  def BalanceBeforeRemove(group: number)
    var future_sizes = copy(this.sizes)
    future_sizes[group] -= 1
    const min_size = min(future_sizes)
    const group_deltas = mapnew(future_sizes, (_, s) => s - min_size)
    for direction in [1, -1]
      const max_group = lib.Find(group_deltas, (d) => d == 2, group, direction)
      if max_group != -1
        this.PercolateFrom(max_group, group_deltas, -direction)
        return
      endif
    endfor
  enddef
endclass
