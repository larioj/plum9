vim9script

import "./lib.vim"

const EXPLORER_FILETYPE = 'nerdtree'

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


class Layout
  this.windows: list<number>
  this.group_sizes: list<number>
  this.max_groups: number

  def GroupWindows(group: number): list<number>
    var start = 0
    for i in range(group)
      start += this.group_sizes[i]
    endfor
    const end = start + this.group_sizes[group]
    return slice(this.windows, start, end)
  enddef

  def GroupOf(window: number): number
    var idx = index(this.windows, window)
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
    const child_idx = index(this.windows, child)
    const child_group = this.GroupOf(child)
    this.group_sizes[child_group] -= 1
    remove(this.windows, child_idx)

    const parent_idx = index(this.windows, parent)
    const parent_group = this.GroupOf(parent)
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

    this.group_sizes[new_child_group] += 1
    insert(this.windows, child, new_child_idx)
    if len(this.group_sizes) > this.max_groups && this.group_sizes[-1] == 0
      remove(this.group_sizes, -1)
    endif
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
      const is_below = min([group, target_group]) % 2 == 1
      win_splitmove(window, target_window, {'rightbelow': is_below})
    endif
    this.group_sizes[group] -= 1
    this.group_sizes[target_group] += 1
    if len(this.group_sizes) > this.max_groups && this.group_sizes[-1] == 0
      remove(this.group_sizes, -1)
    endif
  enddef
endclass

def MakeLayout(partitioner: Partitioner): Layout
  var [type, fragment] = winlayout()
  if type == 'leaf'
    type = 'col'
    fragment = [[type, fragment]]
  endif
  if type == 'col'
    type = 'row'
    fragment = [[type, fragment]]
  endif
  var all_windows = []
  var group_sizes = []
  for i in range(max([len(fragment), partitioner.MaxParts()]))
    var windows = i >= len(fragment) ? [] : Flatten(fragment[i])
    if i == 0 && indexof(windows, (_, w) => IsExplorer(w)) == -1
      add(group_sizes, 0)
    endif
    if len(group_sizes) % 2 == 0
      reverse(windows)
    endif
    add(group_sizes, len(windows))
    extend(all_windows, windows)
  endfor
  return Layout.new(all_windows, group_sizes, partitioner.MaxParts())
enddef

class Balancer
  def PercolateFrom(layout: Layout, group: number, group_deltas: list<number>, direction: number)
    var target_group = lib.Find(group_deltas, (delta) => delta == 0, group, direction)
    while target_group != group
      var start_group = lib.Find(layout.group_sizes, (size) => size > 1, target_group - direction, -direction)
      var cur_group = start_group
      while cur_group != target_group
        layout.MoveFrom(cur_group, direction)
        cur_group += direction
      endwhile
      target_group = start_group
    endwhile
  enddef

  def BalanceAfterInsert(layout: Layout, parent: number, child: number)
    echo layout parent child
    const group = layout.GroupOf(child)
    const min_size = min(layout.group_sizes[1 : ])
    var group_deltas = mapnew(layout.group_sizes, (_, s) => s - min_size)
    group_deltas[0] = 1
    if group_deltas[group] == 0
      return
    endif
    echo group_deltas
    const can_percolate_right = min(group_deltas[group : ]) == 0
    const can_percolate_left = min(group_deltas[0 : group]) == 0
    const group_windows = layout.GroupWindows(group)
    if group_windows[-1] != parent && group_windows[-1] != child && can_percolate_right
      this.PercolateFrom(layout, group, group_deltas, 1)
      this.BalanceAfterInsert(layout, parent, child)
    elseif group_windows[0] != parent && group_windows[0] != child && can_percolate_left
      this.PercolateFrom(layout, group, group_deltas, -1)
      this.BalanceAfterInsert(layout, parent, child)
    elseif can_percolate_right
      this.PercolateFrom(layout, group, group_deltas, 1)
    elseif can_percolate_left
      this.PercolateFrom(layout, group, group_deltas, -1)
    endif
  enddef

  def BalanceBeforeRemove(layout: Layout, group: number)
    var future_sizes = copy(layout.group_sizes)
    future_sizes[group] -= 1
    const min_size = min(future_sizes[1 : ])
    var group_deltas = mapnew(future_sizes, (_, s) => s - min_size)
    group_deltas[0] = 0
    for direction in [1, -1]
      const max_group = lib.Find(group_deltas, (d) => d == 2, group, direction)
      if max_group != -1
        this.PercolateFrom(layout, max_group, group_deltas, -direction)
        return
      endif
    endfor
  enddef
endclass

class WinMan
  this.total_width: number
  this.explorer_width: number
  this.min_window_width: number

  def AfterOpen()
    var partitioner = Partitioner.new(this.total_width, this.explorer_width, this.min_window_width)
    var layout = MakeLayout(partitioner)
    const prev_window = lib.GetWindow('#')
    const cur_window = win_getid()
    if prev_window < 1 || prev_window == cur_window
      return
    endif
    layout.MoveAfter(prev_window, cur_window)
    var balancer = Balancer.new()
    echo 'after new'
    balancer.BalanceAfterInsert(layout, prev_window, cur_window)
  enddef
endclass

def MakeWinMan(explorer_width: number = 30, min_window_width: number = 80): WinMan
  return WinMan.new(&columns, explorer_width, min_window_width)
enddef

export def g:Test()
  # var winman = MakeWinMan()
  # winman.AfterOpen()
  const prev_window = lib.GetWindow('#')
  const cur_window = win_getid()
  echo prev_window cur_window

  var partitioner = Partitioner.new(&columns, 30, 80)
  var layout = MakeLayout(partitioner)
  var balancer = Balancer.new()
  echo partitioner layout balancer
  layout.MoveAfter(prev_window, cur_window)
  echo partitioner layout balancer
  # balancer.BalanceAfterInsert(layout, prev_window, cur_window)
  echo partitioner layout balancer
enddef
