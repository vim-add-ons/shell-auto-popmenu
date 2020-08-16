" vim: set noet fenc=utf-8 ff=unix sts=4 sw=4 ts=4 :
"
" apc.vim - auto popup completion window
"
" Created by skywind on 2020/03/05
" Last Modified: 2020/03/09 20:28
"
" Features:
"
" - auto popup complete window without select the first one
" - tab/s-tab to cycle suggestions, <c-e> to cancel
" - use ApcEnable/ApcDisable to toggle for certiain file.
"
" Usage:
"
" set cpt=.,k,b
" set completeopt=menu,menuone,noselect
" let g:apc_enable_ft = {'text':1, 'markdown':1, 'php':1}

let g:apc_enable_ft = get(g:, 'apc_enable_ft', {})    " enable filetypes
let g:apc_enable_tab = get(g:, 'apc_enable_tab', 1)   " remap tab
let g:apc_enable_auto_popmenu = get(g:, 'apc_enable_auto_popmenu', 1)   " remap tab
let g:apc_min_length = get(g:, 'apc_min_length', 1)   " minimal length to open popup
let g:apc_key_ignore = get(g:, 'apc_key_ignore', [])  " ignore keywords

" get word before cursor
function! s:get_context()
	let str1 = strpart(getline('.'), 0, col('.'))
	let str2 = strpart(get(b:, 'apc_line', ''), 0, get(b:,'apc_curscol', col('.')))
	return len(str1) > len(str2) ? str1 : str2
endfunc

function! s:meets_keyword(context)
	return a:context !~ "^[[:space:]]*$"
	if g:apc_min_length <= 0
		return 0
	endif
	let matches = matchlist(a:context, '\(\k\{' . g:apc_min_length . ',}\)$')
	if empty(matches)
		return 0
	endif
	for ignore in g:apc_key_ignore
		if stridx(ignore, matches[1]) == 0
			return 0
		endif
	endfor
	return 1
endfunc

function! s:check_back_space() abort
	  return col('.') < 2 || getline('.')[col('.') - 2]  =~# '\s'
endfunc

function! s:on_backspace()
	if pumvisible() == 0
		return "\<BS>"
	endif
	let text = matchstr(s:get_context(), '.*\ze.')
	return s:meets_keyword(text)? "\<BS>" : "\<c-e>\<bs>"
endfunc


" autocmd for CursorMovedI
function! s:feed_popup()
	let enable = get(b:, 'apc_enable', 0)
	let lastx = get(b:, 'apc_lastx', -1)
	let lasty = get(b:, 'apc_lasty', -1)
	let tick = get(b:, 'apc_tick', -1)
	if &bt != '' || enable == 0 || &paste
		return -1
	endif
	"echom "APC :: s:feed_popup / b:apc_tick: " . tick . " / b:changedtick: " . b:changedtick
	" Remember before it'll start to be trimmed down by Vim… (somewhat a long
	" story…)
	let prev_line = get(b:, 'apc_line', '')
	let b:apc_line = getline(".")
	let b:apc_curscol = col(".")

	let x = col('.') - 1
	let y = line('.') - 1
	if pumvisible()
		let context = s:get_context()
		if s:meets_keyword(context) == 0
			"echom "APC :: call feedkeys(\"\<c-e>\", '')"
			call feedkeys("\<c-e>", '')
		endif
		let b:apc_lastx = x
		let b:apc_lasty = y
		let b:apc_tick = b:changedtick
		"echom "APC :: s:feedPopup →→ pumvisible() →→ return 0"
		return 0
	elseif lastx == x && lasty == y && b:apc_line == prev_line
		"echom "APC :: lastx == x && lasty == y →→ -2"
		return -2
	elseif b:changedtick == tick
		"echom "APC :: b:changedtick == tick →→ -3"
		let lastx = x
		let lasty = y
		return -3
	endif
	let context = s:get_context()
	if s:meets_keyword(context)
		"echom "APC :: call feedkeys(\"\<c-x>\<c-o>\", 'n')"
		silent! call feedkeys("\<c-x>\<c-o>", 'n')
	endif
	"echom "APC :: s:feedPopup →→ x:".x.",lx:".lastx.", y:".y.",ly:".lasty. " || ['" . prev_line . "']['". b:apc_line ."'] →→ 0"
	let b:apc_lastx = x
	let b:apc_lasty = y
	let b:apc_tick = b:changedtick
	return 0
endfunc

" autocmd for CompleteDone
function! s:complete_done()
	let b:apc_lastx = col('.') - 1
	let b:apc_lasty = line('.') - 1
	let b:apc_tick = b:changedtick
endfunc

" enable apc
function! s:apc_enable()
	call s:apc_disable()
	if g:apc_enable_auto_popmenu
		augroup ApcEventGroup
			au! CursorMovedI <buffer> 
			au CursorMovedI <buffer> nested call s:feed_popup()
			au CompleteDone <buffer> call s:complete_done()
		augroup END
	endif
	let b:apc_init_autocmd = 1
	if g:apc_enable_tab
		inoremap <silent><buffer><expr> <tab>
					\ pumvisible()? "\<c-x>\<c-o>" :
					\ <SID>check_back_space() ? "\<tab>" : "\<c-x>\<c-o>"
		inoremap <silent><buffer><expr> <s-tab>
					\ pumvisible()? "\<c-p>" : "\<s-tab>"
		let b:apc_init_tab = 1
	endif
	inoremap <silent><buffer><expr> <cr> pumvisible()? "\<c-y>" : "\<cr>"
	inoremap <silent><buffer><expr> <bs> <SID>on_backspace()
	let b:apc_init_bs = 1
	let b:apc_init_cr = 1
	let b:apc_save_infer = &infercase
	setlocal infercase
	let b:apc_enable = 1
endfunc

" disable apc
function! s:apc_disable()
	if get(b:, 'apc_init_autocmd', 0)
		augroup ApcEventGroup
			au! CursorMovedI <buffer> 
		augroup END
	endif
	if get(b:, 'apc_init_tab', 0)
		silent! iunmap <buffer><expr> <tab>
		silent! iunmap <buffer><expr> <s-tab>
	endif
	if get(b:, 'apc_init_bs', 0)
		silent! iunmap <buffer><expr> <bs>
	endif
	if get(b:, 'apc_init_cr', 0)
		silent! iunmap <buffer><expr> <cr>
	endif
	if get(b:, 'apc_save_infer', '') != ''
		let &l:infercase = b:apc_save_infer
	endif
	let b:apc_init_autocmd = 0
	let b:apc_init_tab = 0
	let b:apc_init_bs = 0
	let b:apc_init_cr = 0
	let b:apc_save_infer = ''
	let b:apc_enable = 0
endfunc

" check if need to be enabled
function! s:apc_check_init()
	if &bt == '' && get(g:apc_enable_ft, &ft, 0) != 0
		ApcEnable
	elseif &bt == '' && get(g:apc_enable_ft, '*', 0) != 0
		ApcEnable
	else
		let enabled = 0
		if exists('g:shell_omni_completion_loaded')
			if &ft == 'zsh' && get(g:apc_enable_ft, 'zsh', 1) != 0
				let enabled = 1
				ApcEnable
			elseif &ft == 'bash' && get(g:apc_enable_ft, 'bash', 1) != 0
				let enabled = 1
				ApcEnable
			elseif &ft == 'sh' && get(g:apc_enable_ft, 'sh', 1) != 0
				let enabled = 1
				ApcEnable
			endif
		endif
		if !enabled && exists('g:vichord_omni_completion_loaded')
			if &ft == 'vim' && get(g:apc_enable_ft, 'vim', 1) != 0
				ApcEnable
			endif
		endif
	endif
endfunc

" commands & autocmd
command! -nargs=0 -bar ApcEnable call s:apc_enable()
command! -nargs=0 -bar ApcDisable call s:apc_disable()

augroup ApcInitGroup
	au FileType * call s:apc_check_init()
augroup END

let g:apc_loaded = 1
