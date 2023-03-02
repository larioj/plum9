vim9script

b:plum9_actions = get(b:, 'plum9_actions', [])
g:plum9_actions = get(g:, 'plum9_actions', [])
g:plum9_open_cmd = get(g:, 'plum9_open_cmd', 'split')
g:plum9_enable_mouse = get(g: 'plum9_enable_mouse', true)

export def g:Plum9(show_menu: bool = false)
  var actions = []
  for action in b:plum9_actions + g:plum9_actions
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
    actions[1].Execute()
    return
  endif
  const prompt = join(mapnew(actions, (i, a) => i .. ': ' .. a.name), "\n") .. "\n"
  const nr = str2nr(input(prompt))
  actions[nr].Execute()
enddef

###### Enable Mouse    #################################
if g:plum9_enable_mouse
  nnoremap <RightMouse> <LeftMouse>:call Plum9()<cr>
  vnoremap <RightMouse> <LeftMouse>:<c-u>call Plum9()<cr>
  inoremap <RightMouse> <LeftMouse><esc>:call Plum9()<cr>
  nnoremap <S-RightMouse> <LeftMouse>:call Plum9(true)<cr>
  vnoremap <S-RightMouse> <LeftMouse>:<c-u>call Plum9(true)<cr>
  inoremap <S-RightMouse> <LeftMouse><esc>:call Plum9(true)<cr>
endif

###### Default Actions #################################
g:plum9_open_file = {
  'name': 'Open File',
  'IsMatch': () => filereadable(expand('<cfile>')),
  'Execute': () => {
    execute g:plum9_open_cmd
    execute 'gF'
  }
}

g:plum9_change_dir = {
  'name': 'Change Directory',
  'IsMatch': () => isdirectory(expand('<cfile>')),
  'Execute': () => {
    execute g:plum9_open_cmd
    execute 'lcd ' .. expand('<cfile>')
  }
}

g:plum9_open_dir = {
  'name': 'Open Directory',
  'IsMatch': () => isdirectory(expand('<cfile>')),
  'Execute': () => {
    execute g:plum9_open_cmd .. ' ' .. expand('<cfile>')
  }
}

g:plum9_execute = {
  'name': 'Execute Vim Cmd',
  'IsMatch': () => trim(getline('.'))[0] == ':',
  'Execute': () => {
    execute trim(trim(getline('.'))[1:])
  }
}
