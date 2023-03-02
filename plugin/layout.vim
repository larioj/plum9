vim9script

export def MakeLayout(partitioner: Partitioner): Layout
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

