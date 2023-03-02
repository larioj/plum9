vim9script

export def InVisualMode(): bool
  return get(b:, 'plum9_trigger_mode', '') == 'v'
enddef

export def ReadVisualSelection(): string
  const [line_start, column_start] = getpos("'<")[1 : 2]
  const [line_end, column_end] = getpos("'>")[1 : 2]
  var lines = getline(line_start, line_end)
  if len(lines) == 0
      return ''
  endif
  lines[-1] = lines[-1][ : column_end - (&selection == 'inclusive' ? 1 : 2)]
  lines[0] = lines[0][column_start - 1 : ]
  return join(lines, "\n")
enddef

export def ReadFile()
  if InVisualMode()
    return ReadVisualSelection()
  endif
  return expand('<cfile>')
enddef

export def ReadLine()
  if InVisualMode()
    return ReadVisualSelection()
  endif
  return getline('.')
enddef
