vim9script

def plum#fso#IsFile()
  return filereadable(expand('<cfile>'))
enddef

def plum#fso#OpenFile()
  split
  execute 'gF'
enddef
