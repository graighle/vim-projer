"======================================================================
" File: Projer.vim
" Author: Shogo Furusawa <graighle@gmail.com>
" License: WTF Public License {{{
"   This program is free software. It comes without any warranty, to
"   the extent permitted by applicable law. You can redistribute it
"   and/or modify it under the terms of the Do What The Fuck You Want
"   To Public License, Version 2, as published by Sam Hocevar. See
"   http://www.wtfpl.net/ for more details.
" }}}
"======================================================================

if exists('g:loaded_projer')
	finish
endif

let s:save_cpo = &cpo
set cpo&vim

"==================================================
" Commands {{{
command! -n=0 ProjerToggleExplorer	call projer#core#toggle_view({'viewer':'left'})
command! -n=0 ProjerToggleDrives	call projer#core#toggle_view({'module':'drives', 'cursor':'module'})
" }}}

"==================================================
" Setting APIs
"--------------------------------------------------
" Setting APIs {{{
" }}}

let &cpo = s:save_cpo
let g:loaded_projer = 1

" vim: fdm=marker
