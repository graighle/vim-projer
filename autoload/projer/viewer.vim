"======================================================================
" File: viewer.vim
" Author: Shogo Furusawa <graighle@gmail.com>
" License: WTF Public License {{{
"   This program is free software. It comes without any warranty, to
"   the extent permitted by applicable law. You can redistribute it
"   and/or modify it under the terms of the Do What The Fuck You Want
"   To Public License, Version 2, as published by Sam Hocevar. See
"   http://www.wtfpl.net/ for more details.
" }}}
"======================================================================
let s:save_cpo = &cpo
set cpo&vim

let s:viewer = {}
let s:viewer.id = ''
let s:viewer.buffer_name = ''
let s:viewer.location = ''
let s:viewer.size = 20
let s:viewer.module_names = []
let s:viewer.modules = {}

"==================================================
" *** Initializations ***
"--------------------------------------------------
" Create a new viewer
function! projer#viewer#create(params) abort "{{{
	let viewer = copy(s:viewer)
	call viewer.initialize(a:params)

	return viewer
endfunction "}}}

"--------------------------------------------------
" Initialize
function! s:viewer.initialize(params) abort "{{{
	let self.id				= a:params.id
	let self.buffer_name	= a:params.buffer_name
	let self.location		= a:params.location
	let self.size			= a:params.size
	let self.module_names	= split(a:params.modules, ',')

	for module_name in self.module_names
		let self.modules[module_name] = {}
		let self.modules[module_name].is_viewing	= 0
		let self.modules[module_name].range			= {}
	endfor
endfunction "}}}

"==================================================
" *** View Operations ***
"--------------------------------------------------
" Show or hide a module or the viewer
function! s:viewer.toggle_view(options) abort "{{{
	if self.is_open(a:options)
		call self.close(a:options)
	else
		call self.open(a:options)
	endif
endfunction "}}}

" Query whether a module or the viewer is viewing
function! s:viewer.is_open(options) abort "{{{
	let module_name = get(a:options, 'module', '')

	if !bufexists(self.buffer_name) || bufwinnr(self.buffer_name) == -1
		return 0
	endif

	if module_name ==# ''
		return 1
	endif

	return self.modules[module_name].is_viewing
endfunction "}}}

"--------------------------------------------------
" Open a module or the viewer
function! s:viewer.open(options) abort "{{{
	let module_name = get(a:options, 'module', '')

	if !bufexists(self.buffer_name)
		silent! exec self.location . ' vertical ' . self.size . ' new'
		silent! exec 'edit ' . self.buffer_name
	else
		if !self.is_open({})
			silent! exec self.location . ' vertical ' . self.size . ' split'
		endif
		silent! exec 'buffer ' . self.buffer_name
	endif

	setlocal noswapfile
	setlocal undolevels=-1
	setlocal buftype=nofile
	setlocal bufhidden=hide
	setlocal nowrap
	setlocal foldcolumn=0
	setlocal foldmethod=manual
	setlocal nofoldenable
	setlocal nobuflisted
	setlocal nospell
	setlocal nonumber
	setlocal filetype=projer

	if has_key(self.modules, module_name)
		let self.modules[module_name].is_viewing = 1
	endif

	call self.render(a:options)
endfunction "}}}

"--------------------------------------------------
" Close a module or the viewer
function! s:viewer.close(options) abort "{{{
	let module_name = get(a:options, 'module', '')

	if !self.is_open(a:options)
		return
	endif

	if has_key(self.modules, module_name)
		let self.modules[module_name].is_viewing = 0

		if self.is_any_module_viewing()
			call self.render(a:options)
			return
		endif
	endif

	" Don't close the window if there was only one window
	if winnr('$') == 1
		return
	endif

	" If current buffer was viewer, get last accessed buffer
	if winnr() == bufwinnr(self.buffer_name)
		exec 'wincmd p'
		let last_buf = bufnr('')
		exec 'wincmd p'
	else
		let last_buf = bufnr('')
	endif

	exec bufwinnr(self.buffer_name) . ' wincmd w'
	close
	exec bufwinnr(last_buf) . ' wincmd w'
endfunction "}}}

"==================================================
" *** Rendering ***
"--------------------------------------------------
" Redner viewer
function! s:viewer.render(options) abort "{{{
	let module_name = get(a:options, 'module', '')
	let cursor_mode = get(a:options, 'cursor', '')
	let cursor_mode = cursor_mode ==# 'module' ? module_name : cursor_mode

	let restore_pos = getpos('.')

	for module_name in self.module_names
		let self.modules[module_name].range.start_line	= -1
		let self.modules[module_name].range.end_line	= -1
	endfor

	" Clear buffer
	silent 1,$delete _

	" Render modules
	for module_name in self.module_names
		let module = self.modules[module_name]

		if !module.is_viewing
			continue
		endif

		if cursor_mode == module_name
			let restore_pos[1] = line('.') + 1
		endif

		let self.modules[module_name].range.start_line = line('.') + 1
		exec 'call projer#' . module_name . '#render()'
		let self.modules[module_name].range.end_line = line('.')

		call setline(line('.') + 1, '')
		call cursor(line('.') + 1, col('.'))
	endfor

	call setpos('.', restore_pos)
endfunction "}}}

"==================================================
" *** Utilities ***
"--------------------------------------------------
" Query whether any module is viewing
function! s:viewer.is_any_module_viewing() abort "{{{
	for module_name in self.module_names
		if self.modules[module_name].is_viewing
			return 1
		endif
	endfor
	return 0
endfunction "}}}

let &cpo = s:save_cpo

" vim: fdm=marker
