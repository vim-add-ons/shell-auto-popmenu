## shell-auto-popmenu — What Is It ?

It's a fork of the
[skywind3000/vim-auto-popmenu](https://github.com/skywind3000/vim-auto-popmenu)
with patches that make it specifically suited for the [**Shell Omni
Completion**](https://github.com/zphere-zsh/shell-omni-completion) for Vim. It
also contains several bugfixes to make it run smoothly.

Basically, the aim of this plugin is to make the Vim completion popup menu
constantly, automatically active and completing the Zshell [**omni
completion**](https://github.com/zphere-zsh/shell-omni-completion).

## Usage

That's all you need:

```VimL
" The recommended completion options
set completeopt=menu,menuone,noinsert

" suppress annoy messages.
set shortmess+=c

" A command of your Vim plugin manager that'll source the
" zphere-zsh/shell-auto-popmenu plugin
… … …

" If you want an on-demand toggling of the plugin
let g:apc_enable_ft = { 'zsh': 0 }

" If you don't like the default from-single character completing
let g:apc_min_length = 2

" If you want only TAB completing (auto auto pop-menu)
let g:apc_enable_auto_popmenu = 0
```

## Commands

### ApcEnable

Enable plugin for the current buffer manually. Useful when you set
`g:apc_enable_ft.zsh` to `0` (it's `1` by default).

### ApcDisable

Disable plugin for the current buffer.

## Credit

- https://github.com/skywind3000/vim-auto-popmenu

<!-- vim:set ft=markdown tw=80 fo+=a1n autoindent: -->

