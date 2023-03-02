vim9script

import './lib.vim'
import './libterm.vim'

g:plum9_actions = get(g:, 'plum9_actions', [])
g:plum9_open_cmd = get(g:, 'plum9_open_cmd', 'split')
g:plum9_enable_mouse_bindings = get(g:, 'plum9_enable_mouse_bindings', true)
g:plum9_enable_key_bindings = get(g:, 'plum9_enable_key_bindings', true)

export def g:Plum9(trigger_mode: string = 'n', show_menu: bool = false)
  b:plum9_trigger_mode = trigger_mode
  var actions = []
  for action in get(b:, 'plum9_actions', []) + g:plum9_actions
    try
      if action.IsMatch()
        add(actions, action)
      endif
    catch
      echom 'plum9 action [' .. action.name .. '] failed'
    endtry
  endfor
  if len(actions) == 0
    return
  endif
  if len(actions) == 1 || !show_menu
    actions[0].Execute()
    return
  endif
  if len(actions) == 2 && show_menu
    actions[1].Execute()
    return
  endif
  const prompt = join(mapnew(actions, (i, a) => i .. ': ' .. a.name), "\n") .. "\n"
  const nr = str2nr(input(prompt))
  actions[nr].Execute()
enddef

###### Enable Bindings #################################
if g:plum9_enable_mouse_bindings
  nnoremap <RightMouse> <LeftMouse>:call Plum9('n')<cr>
  vnoremap <RightMouse> <LeftMouse>:<c-u>call Plum9('v')<cr>
  inoremap <RightMouse> <LeftMouse><esc>:call Plum9('i')<cr>
  nnoremap <S-RightMouse> <LeftMouse>:call Plum9('n', v:true)<cr>
  vnoremap <S-RightMouse> <LeftMouse>:<c-u>call Plum9('v', v:true)<cr>
  inoremap <S-RightMouse> <LeftMouse><esc>:call Plum9('i', v:true)<cr>
endif

if g:plum9_enable_key_bindings
  nnoremap o :call Plum9('n')<cr>
  vnoremap o :<c-u>call Plum('v')<cr>
  nnoremap O :call Plum9('n', v:true)<cr>
  vnoremap O :<c-u>call Plum('v', v:true)<cr>
endif

###### Default Actions #################################
g:plum9_open_file = {
  'name': 'Open File',
  'IsMatch': () => filereadable(lib.ReadFile()),
  'Execute': () => {
    execute g:plum9_open_cmd
    normal gF
  }
}

g:plum9_change_dir = {
  'name': 'Change Directory',
  'IsMatch': () => isdirectory(lib.ReadFile()),
  'Execute': () => {
    execute g:plum9_open_cmd
    execute 'lcd ' .. lib.ReadFile()
  }
}

g:plum9_open_dir = {
  'name': 'Open Directory',
  'IsMatch': () => isdirectory(lib.ReadFile()),
  'Execute': () => {
    execute g:plum9_open_cmd .. ' ' .. lib.ReadFile()
  }
}

g:plum9_execute = {
  'name': 'Execute Vim Cmd',
  'IsMatch': () => trim(lib.ReadLine())[ : 1] == ': ',
  'Execute': () => {
    execute trim(trim(lib.ReadLine())[1 : ])
  }
}

g:plum9_job = {
  'name': 'Execute Shell Cmd In Vim Job',
  'IsMatch': () => libterm.ReadShellCommand()[ : 1] == '% ',
  'Execute': () => libterm.Job()
}

g:plum9_terminal = {
  'name': 'Execute Shell Cmd In Vim Term',
  'IsMatch': () => libterm.ReadShellCommand()[ : 1] == '$ ',
  'Execute': () => libterm.Terminal()
}
