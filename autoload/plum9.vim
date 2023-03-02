vim9script

import '../plugin/lib.vim'
import '../plugin/libterm.vim'

export def plum9#OpenFile()
  return  {
    'name': 'Open File',
    'IsMatch': () => filereadable(lib.ReadFile()),
    'Execute': () => {
      execute g:plum9_open_cmd
      normal gF
    }
  }
enddef

export def plum9#ChangeDir()
  return {
    'name': 'Change Directory',
    'IsMatch': () => isdirectory(lib.ReadFile()),
    'Execute': () => {
      execute g:plum9_open_cmd
      execute 'lcd ' .. lib.ReadFile()
    }
  }
enddef

export def plum9#OpenDir()
  return {
    'name': 'Open Directory',
    'IsMatch': () => isdirectory(lib.ReadFile()),
    'Execute': () => {
      execute g:plum9_open_cmd .. ' ' .. lib.ReadFile()
    }
  }
enddef

export def plum9#Execute()
  return {
    'name': 'Execute Vim Cmd',
    'IsMatch': () => trim(lib.ReadLine())[ : 1] == ': ',
    'Execute': () => {
      execute trim(trim(lib.ReadLine())[1 : ])
    }
  }
enddef

export def plum9#Job()
  return {
    'name': 'Execute Shell Cmd In Vim Job',
    'IsMatch': () => libterm.ReadShellCommand()[ : 1] == '% ',
    'Execute': () => libterm.Job()
  }
enddef

export def plum9#Terminal()
  return {
    'name': 'Execute Shell Cmd In Vim Term',
    'IsMatch': () => libterm.ReadShellCommand()[ : 1] == '$ ',
    'Execute': () => libterm.Terminal()
  }
enddef

export def plum9#MacUrl()
  return {
    'name': 'Open Url on Mac',
    'IsMatch': () => trim(lib.ReadFile()) =~# '\v^https?://.+$',
    'Execute': () => job_start(['open', trim(lib.ReadFile())])
  }
enddef
