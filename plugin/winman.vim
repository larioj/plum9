vim9script

import "./lib.vim"

export const EXPLORER_FILETYPE = 'nerdtree'

def IsExplorer(window: number): bool
  return getwinvar(window, '&filetype') == EXPLORER_FILETYPE
enddef

def Flatten(fragment: list<any>): list<number>
  var result = []
  var unexplored = [fragment]
  while len(unexplored) > 0
    var [type, children] = remove(unexplored, -1)
    if type == 'leaf'
      add(result, children)
    else
      extend(unexplored, reverse(copy(children)))
    endif
  endwhile
  return result
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
    return partition + lib.Partition(remainder, parts)
  enddef
endclass

class Layout
  this.windows: list<number>
  this.group_sizes: list<number>

  def GroupWindows(group: number): list<number>
    var start = 0
    for i in range(group)
      start += this.group_sizes[i]
    endfor
    const end = start + this.group_sizes[group]
    return slice(this.windows, start, end)
  enddef

  def GroupOf(window: number)
    var idx = index(window, this.windows)
    var sum = 0
    for i in range(len(this.group_sizes))
      sum += this.group_sizes[i]
      if idx < sum
        return i
      endif
    endfor
    return -1
  enddef

  def MoveAfter(parent: number, child: number)
    const parent_idx = index(this.windows, parent)
    const parent_group = this.GroupOf(parent)
    const child_idx = index(this.windows, child)
    const child_group = this.GroupOf(child)
    var new_child_idx = parent_idx + 1
    var new_child_group = parent_group

    if IsExplorer(child)
      # Explorer always goes leftmost
      wincmd H
      new_child_idx = 0
      new_child_group = 0
    endif

    if IsExplorer(parent)
      new_child_group = 1
      if this.group_sizes[1] == 0
        win_splitmove(child, parent, {'vertical': true, 'rightbelow': true})
      else
        win_splitmove(child, this.windows[1])
      endif
    else
      win_splitmove(child, parent, {'rightbelow': parent_group % 2 == 1})
    endif

    this.group_sizes[child_group] -= 1
    remove(this.children, child_idx)
    this.group_sizes[new_child_group] += 1
    insert(this.windows, child, new_child_idx)
  enddef

  def MoveFrom(group: number, direction: number)
    const group_windows = this.GroupWindows(group)
    const target_group = group + direction
    if target_group == len(this.group_sizes)
      add(this.group_sizes, 0)
    endif
    const boundary_idx = direction == 1 ? -1 : 0
    const window = group_windows[boundary_idx]
    if this.group_sizes[target_group] == 0
      wincmd L
    else
      const target_group_windows = this.GroupWindows(target_group)
      const target_window = target_group_windows[boundary_idx]
      const is_below = min(group, target_group) % 2 == 1
      win_splitmove(window, target_window, {'rightbelow': is_below})
    endif
    this.group_sizes[group] -= 1
    this.group_sizes[target_group] += 1
  enddef
endclass

def MakeLayout(): Layout
  var [type, fragment] = winlayout()
  var all_windows = []
  var group_sizes = []
  if type == 'leaf'
    type = 'col'
    fragment = [[type, fragment]]
  endif
  if type == 'col'
    type = 'row'
    fragment = [[type, fragment]]
  endif
  for i in range(len(fragment))
    var windows = Flatten(fragment[i])
    if i == 0 && indexof(windows, (_, w) => IsExplorer(w)) == -1
      add(group_sizes, 0)
    endif
    if len(group_sizes) % 2 == 0
      reverse(windows)
    endif
    add(group_sizes, len(windows))
    extend(all_windows, windows)
  endfor
  return Layout.new(all_windows, group_sizes)
enddef

class Balancer
  this.layout: Layout

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


export class WinMan
  this.total_width: number
  this.explorer_width: number
  this.min_window_width: number

  def AfterOpen()
    cont window_count = winnr('$')
    if window_count == 1
      return
    endif
    const first_window = GetWindow(1)
    const has_explorer = getwinvar(first_window, '&filetype') == EXPLORER_FILETYPE
    const partitioner = Partitioner.new(this.total_width, this.explorer_width, this.min_window_width)
    const max_parts = partitioner.MaxParts()
    cont window_count = winnr('$')
    const prev_window = GetWindow('#')
    const cur_window = GetWindow('0j')
    if window_count <= max_parts + (has_explorer ? 1 : 0)
      # move cur to be to the right of prev
      return
    endif
    if has_explorer && prev_window == first_window
      # Move new window above second windaw
      return
    endif

    # Move window above or below parent depending on column
  enddef
endclass


export def g:Test()
  echo MakeLayout()
enddef


