# Plum9 from Outer Space

## Files
- plugin/plum9.vim
- autoload/plum9.vim

## Configuration
```
let g:plum9_actions = [
      \ g:plum9#OpenFile(),
      \ g:plum9#ChangeDir(),
      \ g:plum9#OpenDir(),
      \ g:plum9#Execute(),
      \ g:plum9#Job(),
      \ g:plum9#Terminal(),
      \ g:plum9#MacUrl()
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
% echo
```

- $HOME/.vimrc
