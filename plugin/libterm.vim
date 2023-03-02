vim9script

import './lib.vim'

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

export def ReadShellCommand(): string
  if lib.InVisualMode()
    return Normalize(lib.ReadVisualSelection())
  endif
  var end = line('.') + 1
  var lines = [getline('.')]
  while lines[-1][-1] == '\'
    add(lines, getline(end))
    end += 1
  endwhile
  if lines[-1][-5 : ] == '<<EOF' || lines[-1][-7 : ] != "<<'EOF'"
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

export def Terminal(exp: string = trim(ReadShellCommand()[2 : ]))
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

export def Job(exp: string = trim(ReadShellCommand()[2 : ]))
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
