vim9script

const EXPLORER_FILETYPE = 'nerdtree'

export class WinMan
  def AfterOpen()
    const prev_window = GetWindow('#')
    if !prev_window
      return
    endif
    const first_window = GetWindow(1)
    const has_explorer = getwinvar(first_window, '&filetype') == EXPLORER_FILETYPE
    const explorer = has_explorer ? first_window : 0
    if prev_window == explorer
      # Move new window above second windaw
      # Or Move window to the left of second window
    endif



    const layout = Layout(has_explorer, explorer_width, min_window_width)
  enddef
endclass
