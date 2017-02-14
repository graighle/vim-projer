"======================================================================
" File: core.vim
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

"==================================================
" *** Parameters ***
"--------------------------------------------------
" Default modules for each viewers {{{
if !exists('g:projer_left_modules')
	let g:projer_left_modules = 'drives,filetree'
endif
if !exists('g:projer_right_modules')
	let g:projer_right_modules = ''
endif
if !exists('g:projer_top_modules')
	let g:projer_top_modules = ''
endif
if !exists('g:projer_bottom_modules')
	let g:projer_bottom_modules = ''
endif
" }}}

"--------------------------------------------------
" Default buffer name of each viewers {{{
if !exists('g:projer_left_buffer_name') || g:projer_left_buffer_name ==# ''
	let g:projer_left_buffer_name = 'projer_left'
endif
if !exists('g:projer_right_buffer_name') || g:projer_right_buffer_name ==# ''
	let g:projer_right_buffer_name = 'projer_right'
endif
if !exists('g:projer_top_buffer_name') || g:projer_top_buffer_name ==# ''
	let g:projer_top_buffer_name = 'projer_top'
endif
if !exists('g:projer_bottom_buffer_name') || g:projer_bottom_buffer_name ==# ''
	let g:projer_bottom_buffer_name = 'projer_bottom'
endif
" }}}

"--------------------------------------------------
" Default size of each viewers {{{
if !exists('g:projer_left_size') || g:projer_left_size ==# ''
	let g:projer_left_size = 20
endif
if !exists('g:projer_right_size') || g:projer_right_size ==# ''
	let g:projer_right_size = 20
endif
if !exists('g:projer_top_size') || g:projer_top_size ==# ''
	let g:projer_top_size = 20
endif
if !exists('g:projer_bottom_size') || g:projer_bottom_size ==# ''
	let g:projer_bottom_size = 20
endif
" }}}

"--------------------------------------------------
" Viewer locations
let s:locations = {}
let s:locations.left	= 'topleft'
let s:locations.right	= 'botright'
let s:locations.top		= 'aboveleft'
let s:locations.bottom	= 'belowright'

"--------------------------------------------------
" Events
let g:projer_basic_events = 'Decide'
if !exists('g:projer_extra_events')
	let g:projer_extra_events = ''
endif

"--------------------------------------------------
let t:projer_core_is_init = 0
let t:projer_viewers = {}

"==================================================
" *** Initializations ***
"--------------------------------------------------
" Initialize projer core
function! s:initialize() abort "{{{
	if t:projer_core_is_init
		return
	endif

	let t:projer_viewers = {}
	for viewer_name in ['left', 'right', 'top', 'bottom']
		let t:projer_viewers[viewer_name] = s:create_viewer(viewer_name)
	endfor

	let t:projer_core_is_init = 1
endfunction "}}}

"--------------------------------------------------
" Create a viewer
function! s:create_viewer(viewer_name) abort "{{{
	let params = {}
	let params.id			= a:viewer_name
	let params.buffer_name	= eval('g:projer_' . a:viewer_name . '_buffer_name')
	let params.location		= s:locations[a:viewer_name]
	let params.size			= eval('g:projer_' . a:viewer_name . '_size')
	let params.modules		= eval('g:projer_' . a:viewer_name . '_modules')

	return projer#viewer#create(params)
endfunction "}}}

"==================================================
" View Operations
"--------------------------------------------------
" Show or hide a module or a viewer
function! projer#core#toggle_view(options) abort "{{{
	if !t:projer_core_is_init
		call s:initialize()
	endif

	let viewer_name = s:get_target_viewer_name(a:options)
	call t:projer_viewers[viewer_name].toggle_view(a:options)
endfunction "}}}

"--------------------------------------------------
" Query whether a module or a viewer is showing or hiding
function! projer#core#is_open(options) abort "{{{
	if !t:projer_core_is_init
		call s:initialize()
	endif

	let viewer_name = s:get_target_viewer_name(a:options)
	return t:projer_viewers[viewer_name].is_open(a:options)
endfunction "}}}

"--------------------------------------------------
" Open a module or a viewer
function! projer#core#open_view(options) abort "{{{
	if !t:projer_core_is_init
		call s:initialize()
	endif

	let viewer_name = s:get_target_viewer_name(a:options)
	if viewer_name ==# ''
		echomsg 'No viewer assigned to ' . get(a:options, 'module', '') . ' module'
	else
		call t:projer_viewers[viewer_name].open(a:options)
	endif
endfunction "}}}

"--------------------------------------------------
" Close a module or a viewer
function! projer#core#close_view(options) abort "{{{
	if !t:projer_core_is_init
		call s:initialize()
	endif

	let viewer_name = s:get_target_viewer_name(a:options)
	call t:projer_viewers[viewer_name].close(a:options)
endfunction "}}}

"==================================================
" *** Events ***
"--------------------------------------------------
" Event Handler
function! projer#core#on_event(viewer_name, event, ...) abort "{{{
	call t:projer_viewers[a:viewer_name].on_event(a:event, a:000)
endfunction "}}}

"==================================================
" *** Utilities ***
"--------------------------------------------------
" Get target viewer name by specified options
function! s:get_target_viewer_name(options) abort "{{{
	let viewer_name = get(a:options, 'viewer', '')
	if viewer_name !=# ''
		return viewer_name
	endif

	let module_name = get(a:options, 'module', '')
	for [viewer_name, viewer] in items(t:projer_viewers)
		if index(viewer.module_names, module_name) != -1
			return viewer_name
		endif
	endfor

	return ''
endfunction "}}}

let &cpo = s:save_cpo

" vim: fdm=marker
