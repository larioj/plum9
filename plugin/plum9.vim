vim9script

g:plum9_actions = get(g:, 'plum9_actions', [])
b:plum9_actions = get(b:, 'plum9_actions', [])

interface Action
  def IsMatch(mode: string, trigger: string): bool
  def Execute(mode: string, trigger: string): any
endinterface

export def g:Plum9(mode: string = 'n', trigger: string = '')
  const actions = <list<Action>>(b:plum9_actions) + <list<Action>>(g:plum9_actions)
  for action in actions
    if action.IsMatch(mode, trigger)
      action.Execute(mode, trigger)
    endif
  endfor
enddef
