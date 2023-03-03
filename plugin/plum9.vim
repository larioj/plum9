vim9script

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
  if !show_menu
    if len(actions) > 0
      actions[0].Execute()
    endif
    return
  endif
  const options = mapnew(actions, (i, a) => i .. ': ' .. a.name)
  const nr = inputlist(options)
  if nr >= 0 && nr < len(actions)
    actions[nr].Execute()
  endif
enddef

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
