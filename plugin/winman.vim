vim9script

const EXPLORER_FILETYPE = 'nerdtree'

def GetWindow(alias: any): number
  return win_getid(winnr(alias))
enddef

def Divide(numerator: number, denominator: number): list<number>
  var div = numerator / denominator
  var rem = numerator % denominator
  var result = []
  for i in range(denominator)
    var amount = div + (i < rem ? 1 : 0)
    add(result, amount)
  endfor
  return result
enddef

class Layout
  this.has_explorer: bool
  this.explorer_width: number
  this.min_window_width: number
  this.stack_widths: list<number>
  def new(has_explorer: bool = true, explorer_width: number = 30, min_window_width: number = 80)
    this.explorer_width = explorer_width
    this.min_window_width = min_window_width
    const stack_count = &columns / min_window_width
    const available_columns = has_explorer ? &columns - explorer_width : &columns
    this.stack_widths = Divide(available_columns, stack_count)
  enddef
endclass





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
