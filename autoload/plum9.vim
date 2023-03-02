vim9script

##### Library #####################################
def InVisualMode(): bool
  return get(b:, 'plum9_trigger_mode', '') == 'v'
enddef

def ReadVisualSelection(): string
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

def ReadFile(): string
  if InVisualMode()
    return ReadVisualSelection()
  endif
  return expand('<cfile>')
enddef

def ReadLine(): string
  if InVisualMode()
    return ReadVisualSelection()
  endif
  return getline('.')
enddef

def Normalize(cmd: string): string
  var first_parts = []
  var rest = []
  for l in split(cmd, "\n")
    if len(first_parts) == 0 || first_parts[-1][-1] == '\'
      add(first_parts, l)
    else
      add(rest, l)
    endif
  endfor
  const first = join(mapnew(first_parts, (_, l) => trim(l[-1] == '\' ? l[ : -2] : l)), ' ')
  return trim(join([first] + rest, "\n"))
enddef

def ReadShellCommand(): string
  if InVisualMode()
    return Normalize(ReadVisualSelection())
  endif
  var end = line('.') + 1
  var lines = [getline('.')]
  while lines[-1][-1] == '\'
    add(lines, getline(end))
    end += 1
  endwhile
  if lines[-1][-5 : ] == '<<EOF' || lines[-1][-7 : ] == "<<'EOF'"
    while end <= line('$')
      add(lines, getline(end))
      end += 1
      if trim(lines[-1]) == 'EOF'
        break
      endif
    endwhile
  endif
  return Normalize(join(lines, "\n"))
enddef

def CloseIfEmpty(winid: number, status: number, wait: bool = true)
  const bufnr = winbufnr(winid)
  if wait
    term_wait(bufnr, 1000)
  endif
  const bufcontent = trim(join(getbufline(bufnr, 1, '$'), "\n"))
  if status == 0 && len(bufcontent) == 0
    exe bufnr .. ' bwipe!'
  endif
enddef

def TerminalStart(exp: string = trim(ReadShellCommand()[2 : ]))
  const name = exp[ : 30] .. (len(exp) > 30 ? '...' : '')
  const open_cmd = get(g:, 'plum9_open_cmd', 'split')
  const cwd = getcwd()
  $vimfile = expand('%')
  execute open_cmd
  const winid = win_getid()
  const options = {
    'exit_cb': (_, status) => CloseIfEmpty(winid, status),
    'term_name': name,
    'curwin': 1,
    'term_finish': 'open',
    'cwd': cwd
  }
  term_start(['/bin/bash', '-ic', exp], options)
enddef

def OpenScratchBuffer(name: string)
  const open_cmd = get(g:, 'plum9_open_cmd', 'split')
  execute open_cmd
  noswapfile hide enew
  setlocal buftype=nofile
  setlocal bufhidden=hide
  execute 'file ' .. printf('[%x] %s', localtime(), name)
enddef

def JobStart(exp: string = trim(ReadShellCommand()[2 : ]))
  const name = exp[ : 30] .. (len(exp) > 30 ? '...' : '')
  const cwd = getcwd()
  $vimfile = expand('%')
  OpenScratchBuffer(name)
  const nr = bufnr()
  const winid = win_getid()
  const options = {
    'exit_cb': (_, status) => CloseIfEmpty(winid, status, false),
    'cwd': cwd,
    'out_io': 'buffer',
    'err_io': 'buffer',
    'out_buf': nr,
    'err_buf': nr,
    'in_io': 'pipe'
  }
  b:plum9_job = job_start(['/bin/bash', '-ic', exp], options)
enddef


##### Actions #####################################
export def OpenFile(): dict<any>
  return  {
    'name': 'Open File',
    'IsMatch': () => filereadable(ReadFile()),
    'Execute': () => {
      execute g:plum9_open_cmd
      normal gF
    }
  }
enddef

export def ChangeDir(): dict<any>
  return {
    'name': 'Change Directory',
    'IsMatch': () => isdirectory(ReadFile()),
    'Execute': () => {
      execute g:plum9_open_cmd
      execute 'lcd ' .. ReadFile()
    }
  }
enddef

export def OpenDir(): dict<any>
  return {
    'name': 'Open Directory',
    'IsMatch': () => isdirectory(ReadFile()),
    'Execute': () => {
      execute g:plum9_open_cmd .. ' ' .. ReadFile()
    }
  }
enddef

export def MacUrl(): dict<any>
  return {
    'name': 'Open Url on Mac',
    'IsMatch': () => trim(ReadFile()) =~# '\v^https?://.+$',
    'Execute': () => job_start(['open', trim(ReadFile())])
  }
enddef

export def Execute(): dict<any>
  return {
    'name': 'Execute Vim Cmd',
    'IsMatch': () => trim(ReadLine())[ : 1] == ': ',
    'Execute': () => {
      execute trim(trim(ReadLine())[1 : ])
    }
  }
enddef

export def Job(): dict<any>
  return {
    'name': 'Execute Shell Cmd In Vim Job',
    'IsMatch': () => ReadShellCommand()[ : 1] == '% ',
    'Execute': () => JobStart()
  }
enddef

export def Terminal(): dict<any>
  return {
    'name': 'Execute Shell Cmd In Vim Term',
    'IsMatch': () => ReadShellCommand()[ : 1] == '$ ',
    'Execute': () => TerminalStart()
  }
enddef
