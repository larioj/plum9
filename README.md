# Plum9 from Outer Space

## Files
- plugin/plum9.vim
- autoload/plum9.vim
- $HOME/.vimrc

## Configuration
```
let g:plum9_actions = [
      \ g:plum9#GoToDiff(),
      \ g:plum9#Execute(),
      \ g:plum9#Job(),
      \ g:plum9#Terminal(),
      \ g:plum9#MacUrl(),
      \ g:plum9#OpenFile(),
      \ g:plum9#OpenDir(),
      \ g:plum9#ChangeDir()
      \ ]
```

## Examples
```
% echo hello \
   foo \
  bar
% git add . && git commit -m "more" && git push
% echo hello
% git status
% git diff
% set -ex; FL=$(mktemp) && git diff > $FL
% mktemp
% echo
$ echo $HOME
$ git diff
: PlugUpdate



```
