"======================================================================
" File: drives.vim
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

let s:drives = []
let b:render_drives = {}

"==================================================
" *** Initializations ***
"--------------------------------------------------
" Initialize
function! s:initialize() abort "{{{
	if has('win32') || has('win64')
		call s:initialize_windows_drives()
	else
		call s:initialize_unix_drives()
	endif
endfunction "}}}

"--------------------------------------------------
" Initialize Windows drives
function! s:initialize_windows_drives() abort "{{{
	let candidates = map(range(char2nr('A'), char2nr('Z')), 'nr2char(v:val) . ":"')
	let s:drives = []
	for name in filter(candidates, 'isdirectory(v:val . "/")')
		let drive = {}
		let drive.name = name
		let drive.path = name . '/'
		call add(s:drives, drive)
	endfor
endfunction "}}}

"--------------------------------------------------
" Initialize Unix drives
function! s:initialize_unix_drives() abort "{{{
	let drive = {}
	let drive.name = '/'
	let drive.path = '/'
	call add(s:drives, drive)

	let drive = {}
	let drive.name = '~'
	let drive.path = expand('$HOME')
	call add(s:drives, drive)
endfunction "}}}

"==================================================
" *** Rendering ***
"--------------------------------------------------
" Render drives
function! projer#drives#render() abort "{{{
	let b:render_drives = {}

	" Render title
	call setline(line('.') + 1, '>>> Drives >>>-----')
	call cursor(line('.') + 1, col('.'))

	for drive in s:drives
		let line = line('.') + 1
		let b:render_drives[drive.path] = line

		call setline(line, ' +' . drive.name)
		call cursor(line, col('.'))
	endfor
endfunction "}}}

"==================================================
" Call initialize on loading
call s:initialize()

let &cpo = s:save_cpo

" vim: fdm=marker
