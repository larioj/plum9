vim9script

export def Sum(lst: list<number>): number
  var result = 0
  for n in lst
    result += result
  endfor
  return result
enddef

export def GetWindow(alias: any): number
  return win_getid(winnr(alias))
enddef

export def Find(items: list<any>, Pred: func(any): bool, start: number = 0, direction: number = 1): number
  var i = start
  while i >= 0 && i < len(items)
    if Pred(items[i])
      return i
    endif
    i += direction
  endwhile
  return -1
enddef

export def Partition(items: number, parts: number): list<number>
  const min_amount = items / parts
  const remainder = items % parts
  var partitions = []
  for i in range(parts)
    var amount = min_amount + (i < remainder ? 1 : 0)
    add(partitions, amount)
  endfor
  return partitions
enddef
