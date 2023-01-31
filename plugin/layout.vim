vim9script

class GroupedList
  groups: list<list<number>>
endclass

def IsWithinBounds(idx: number, lst: list<any>): bool
  return idx >= 0 && idx < len(lst)
enddef

def FirstIndex(stack: number): number
  return stack % 2 ? -1 : 0
enddef

def FirstWindow(stacks: list<list<number>>, stack: number): number
  return stacks[stack][FirstIndex(stack)]
enddef

def LastIndex(stack: number): number
  return stack % 2 ? 0 : -1
enddef

def LastWindow(stacks: list<list<number>>, stack: number): number
  return stacks[stack][LastIndex(stack)]
enddef

def Find(items: list<any>, item: any, start: number, direction: number = 1): number
  var i = start
  while i >= 0 && i < len(items)
    if items[i] == item
      return i
    endif
    i += direction
  endwhile
  return -1
enddef

def AfterOpen(stacks: list<list<number>>, stack: number, parent: number, child: number)
  const stack_sizes = mapnew(stacks, (_, s) => len(s))
  const min_stack_size = min(stack_sizes)
  const stack_deltas = mapnew(stack_sizes, (_, s) => s - min_stack_size)
  if stack_deltas[stack] > 0
    const can_percolate_right = min(stack_deltas[stack : ]) == 0
    const can_percolate_left = min(stack_deltas[0 : stack]) == 0
    if LastWindow(stacks, stack) != parent && LastWindow(stacks, stack) != child && can_percolate_right
      Percolate(1, stacks, stack, stack_deltas)
      AfterOpen(stacks, stack, parent, child)
    elseif FirstWindow(stacks, stack) != parent && FirstWindow(stacks, stack) != child && can_percolate_left
      Percolate(-1, stacks, stack, stack_deltas)
      AfterOpen(stacks, stack, parent, child)
    else # we move child
      Percolate(1, stacks, stack, stack_deltas)
    endif
  endif
enddef

def BeforeClose(stacks: list<list<number>>, stack: number)
  const stack_sizes = mapnew(stacks, (i, s) => i == stack ? len(s) - 1 : len(s))
  const min_stack_size = min(stack_sizes)
  const stack_deltas = mapnew(stack_sizes, (_, s) => s - min_stack_size)
  echo stack_deltas
  var max_stack = Find(stack_deltas, 2, stack, 1)
  var direction = -1
  if max_stack == -1
    max_stack = Find(stack_deltas, 2, stack, -1)
    direction = 1
  endif
  echo max_stack
  echo direction
  if max_stack != -1
    Percolate(direction, stacks, max_stack, stack_deltas)
  endif
enddef

def Move(stacks: list<list<number>>, source: number, dest: number)
  var source_idx = 0
  var dest_idx = 0
  var dest_window = stacks[dest][dest_idx]
  var relative_location = 'above'
  if min([source, dest]) % 2 == 0
    source_idx = len(stacks[source]) - 1
    dest_idx = len(stacks[dest])
    dest_window = stacks[dest][dest_idx - 1]
    relative_location = 'below'
  endif
  const window = remove(stacks[source], source_idx)
  echo 'moving ' .. window .. ' ' .. relative_location .. ' ' .. dest_window 
  insert(stacks[dest], window, dest_idx)
enddef

def Percolate(direction: number, stacks: list<list<number>>, stack: number, stack_deltas: list<number>)
  var target_stack = stack
  while stack_deltas[target_stack] > 0 && target_stack + direction >= 0 && target_stack + direction < len(stacks)
    target_stack += direction
  endwhile
  while target_stack != stack
    var start_stack = target_stack - direction
    while len(stacks[start_stack]) < 2
      start_stack -= direction
    endwhile
    var cur_stack = start_stack
    while cur_stack != target_stack
      Move(stacks, cur_stack, cur_stack + direction)
      cur_stack += direction
    endwhile
    target_stack = start_stack
  endwhile
enddef

export def g:TestTabLayout()
  var stacks = [[1, 2], [4]]
  echo stacks
  AfterOpen(stacks, 0, 1, 2)
  echo stacks
enddef
