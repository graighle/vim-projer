"======================================================================
" File: filetree.vim
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

let t:root = {}
let b:render_dirs = {}

"==================================================
" *** Rendering ***
"--------------------------------------------------
" Render filetree
function! projer#filetree#render() abort "{{{
	let b:render_dirs = {}

	" Render title
	call setline(line('.') + 1, '>>> Files >>>------')
	call cursor(line('.') + 1, col('.'))

	let b:render_dirs[0] = []
	let render_info = { 'dir_id':'', 'dir_line':line('.') + 1 }

	" Render root
	call setline(line('.') + 1, '<' . t:root.path . '>')
	call cursor(line('.') + 1, col('.'))

	" Render tree
	call add(b:render_dirs[0], render_info)
	call s:render_nodes(t:root.children, 1, '')
	let render_info.last_child_line = line('.')
endfunction "}}}

"--------------------------------------------------
" Render nodes
function! s:render_nodes(nodes, depth, parent) abort "{{{
	let depth_prefix = ' ' . repeat('| ', a:depth - 1)
	let nodes_size = len(a:nodes)

	if !has_key(b:render_dirs, a:depth)
		let b:render_dirs[a:depth] = []
	endif

	for node_idx in range(0, nodes_size - 1)
		let line = line('.') + 1
		let node = a:nodes[node_idx]
		let node_prefix = node_idx == nodes_size - 1 ? '`' : '|'
		let node_prefix .= !node.is_dir ? '-' : (node.is_open ? '~' : '+')

		call setline(line, depth_prefix . node_prefix . node.name)
		call cursor(line, col('.'))
		if node.is_dir
			let dir_id = s:make_dir_id(a:parent, node_idx, node.name)
			let render_info = { 'dir_id':dir_id, 'dir_line':line }
			call add(b:render_dirs[a:depth], render_info)

			if node.is_open
				call s:render_nodes(node.children, a:depth + 1, dir_id)
			endif

			let render_info.last_child_line = line('.')
		endif
	endfor
endfunction "}}}

"==================================================
" *** Events ***
"--------------------------------------------------
" Event Handler
function! projer#filetree#on_event(event, args) abort "{{{
	let fun = 's:on_event_' . tolower(a:event)
	if exists('*' . fun)
		exec 'call ' . fun . '(a:args)'
	endif
endfunction "}}}

"--------------------------------------------------
" Decide event: Open a file or a directory
function! s:on_event_decide(args) abort "{{{
	let detected = s:detect_node_on_line(line('.'))

	if detected.type ==# 'dir'
		call s:open_directory(detected.node)
		call projer#core#open_view({ 'module':'filetree' })
	elseif detected.type ==# 'file'
		call s:open_file(detected.node)
	endif
endfunction "}}}

"==================================================
" *** Node Initializations ***
"--------------------------------------------------
" Read children of a node
function! s:read_children(node) abort "{{{
	let joined_filenames = globpath(a:node.path, '*')

	let dirs = []
	let files = []
	for file in split(joined_filenames, '\n')
		let child = s:create_node(file)
		if child.is_dir
			call add(dirs, child)
		else
			call add(files, child)
		endif
	endfor

	let a:node.children = dirs + files
endfunction "}}}

"--------------------------------------------------
" Create a node
function! s:create_node(file) abort "{{{
	let node = {}
	let node.is_dir = isdirectory(a:file)
	let node.is_open = 0
	let node.path = a:file
	let node.name = split(a:file, '\')[-1] . (node.is_dir ? '/' : '')
	return node
endfunction "}}}

"==================================================
" *** Node Operatoins ***
"--------------------------------------------------
" Open a path as root
function! projer#filetree#change_root(name, path) abort "{{{
	let t:root = {}
	let t:root.path = a:path

	call s:read_children(t:root)
endfunction "}}}

"--------------------------------------------------
" Open a directory
function! s:open_directory(node) abort "{{{
	if !has_key(a:node, 'children')
		call s:read_children(a:node)
	endif
	let a:node.is_open = !a:node.is_open
endfunction "}}}

"--------------------------------------------------
" Open a file
function! s:open_file(node) abort "{{{
	let win = bufwinnr('^' . a:node.path . '$')
	if win != -1
		exec win . ' wincmd w'
	endif

	exec 'wincmd p'
	exec 'edit ' . a:node.path
endfunction "}}}

"--------------------------------------------------
" Analyze depth of node
function! s:analyze_depth(str) abort "{{{
	let depth = 0
	let pos = 0
	let str_size = len(a:str)

	while pos < str_size
		if pos + 1 >= str_size
			break
		elseif a:str[pos] == '~'
			break
		elseif a:str[pos] == ' ' && (a:str[pos + 1] == '|' || a:str[pos + 1] == '`')
			let depth = depth + 1
			let pos = pos + 2
		else
			break
		endif
	endwhile

	return depth
endfunction "}}}

"==================================================
" *** Node Utilities ***
"--------------------------------------------------
" Make Directory ID of a directory node
function! s:make_dir_id(parent, node_index, node_name) abort "{{{
	return a:parent . a:node_index . ':' . a:node_name
endfunction "}}}

"--------------------------------------------------
" Find node by Directory ID
function! s:find_node_by_dir_id(dir_id) abort "{{{
	let node = t:root
	for dir in split(a:dir_id, '/')
		let node = node.children[split(dir, ':')[0]]
	endfor
	return node
endfunction "}}}

"--------------------------------------------------
" Detect node
function! s:detect_node_on_line(line) abort "{{{
	let node_str = getline(a:line)
	if node_str ==# '' || node_str[0] !=# ' '
		return { 'type' : '' }
	endif

	let open_depth = s:analyze_depth(node_str)

	" Search opening directory in same depth
	for dir in b:render_dirs[open_depth]
		if dir.dir_line == a:line
			let opening_dir = dir
			break
		endif
	endfor

	" Open the directory
	if exists('opening_dir')
		return { 'type' : 'dir', 'node' : s:find_node_by_dir_id(opening_dir.dir_id) }
	endif

	" Search parent directory in parent depth
	for dir in b:render_dirs[open_depth - 1]
		if dir.dir_line > a:line
			break
		endif
		let parent_dir = dir
	endfor

	if !exists('parent_dir')
		return
	endif

	let parent_node = s:find_node_by_dir_id(parent_dir.dir_id)
	let opening_node = parent_node.children[len(parent_node.children) - (parent_dir.last_child_line - a:line) - 1]

	return { 'type' : 'file', 'node' : opening_node }
endfunction "}}}

let &cpo = s:save_cpo

" vim: fdm=marker
