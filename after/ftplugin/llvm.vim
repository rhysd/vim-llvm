" Copyright (c) 2018 rhysd
"
" Permission is hereby granted, free of charge, to any person obtaining a copy
" of this software and associated documentation files (the "Software"), to deal
" in the Software without restriction, including without limitation the rights
" to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
" copies of the Software, and to permit persons to whom the Software is
" furnished to do so, subject to the following conditions:
"
" The above copyright notice and this permission notice shall be included in
" all copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
" IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
" FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
" AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
" LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
" OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
" THE SOFTWARE.

if get(g:, 'llvm_extends_official', 1) == 0
    finish
endif

let g:llvm_ext_no_mapping = get(g:, 'llvm_ext_no_mapping', 0)

let s:KIND_BLOCK_PREC = 0
let s:KIND_BLOCK_FOLLOW = 1
let s:KIND_FUNC_BEGIN = 2
let s:KIND_FUNC_END = 3

function! s:section_delim_at(lnum) abort
    let line = getline(a:lnum)
    let m = matchlist(line, '^\([^:]\+\):\%( \+; preds = \(%.\+\)\)\=$')
    if !empty(m)
        if m[2] ==# ''
            return [s:KIND_BLOCK_PREC, m[1]]
        else
            return [s:KIND_BLOCK_FOLLOW, m[1], split(m[2], ',\s*')]
        endif
    endif
    if line =~# '^}$'
        return [s:KIND_FUNC_END]
    endif
    if line =~# '^define\>'
        return [s:KIND_FUNC_BEGIN]
    endif
    return []
endfunction

function! s:is_section_delim(line, func_delim) abort
    let sec = s:section_delim_at(a:line)
    if empty(sec)
        return 0
    endif
    let kind = sec[0]
    return kind == s:KIND_BLOCK_PREC || kind == s:KIND_BLOCK_FOLLOW || kind == func_delim
endfunction

function! s:next_section(stop_func_begin) abort
    let func_delim = a:stop_func_begin ? s:KIND_FUNC_BEGIN : s:KIND_FUNC_END
    let last = line('$') - 1
    let line = line('.')
    while line < last
        let line += 1
        if s:is_section_delim(line, func_delim)
            call cursor(line, col('.'))
            return
        endif
    endwhile
endfunction

function! s:prev_section(stop_func_begin) abort
    let func_delim = a:stop_func_begin ? s:KIND_FUNC_BEGIN : s:KIND_FUNC_END
    let line = line('.')
    while line > 1
        let line -= 1
        if s:is_section_delim(line, func_delim)
            call cursor(line, col('.'))
            return
        endif
    endwhile
endfunction

if !g:llvm_ext_no_mapping
    nnoremap <buffer><silent>]] :<C-u>call <SID>next_section(1)<CR>
    nnoremap <buffer><silent>[[ :<C-u>call <SID>prev_section(1)<CR>
    nnoremap <buffer><silent>][ :<C-u>call <SID>next_section(0)<CR>
    nnoremap <buffer><silent>[] :<C-u>call <SID>prev_section(0)<CR>
endif

function! s:function_range_at(linum) abort
    let line = a:linum
    while line >= 1
        let s = getline(line)
        if s =~# '^define\>'
            let start = line
            break
        elseif s =~# '^}$'
            return []
        endif
        let line -= 1
    endwhile
    if line < 1
        return []
    endif

    let line = a:linum
    let last = line('$')
    while line <= last
        let s = getline(line)
        if s =~# '^}$'
            let end = line
            break
        elseif s =~# '^define\>'
            return []
        endif
        let line += 1
    endwhile
    if line > last
        return []
    endif

    return [start, end]
endfunction

function! s:blocks_graph_at(linum) abort
    let func_range = s:function_range_at(a:linum)
    if empty(func_range)
        return {}
    endif
    let line = func_range[0] + 1
    let last = func_range[1] - 1
    let graph = {}
    while line <= last
        let block = s:section_delim_at(line)
        if empty(block)
            let line += 1
            continue
        endif
        let block_name = '%' . block[1]
        if block[0] == s:KIND_BLOCK_PREC
            let graph[block_name] = {'line': line, 'follows': [], 'preds': []}
        elseif block[0] == s:KIND_BLOCK_FOLLOW
            let graph[block_name] = {'line': line, 'follows': [], 'preds': block[2]}
            for follow in block[2]
                call add(graph[follow].follows, block_name)
            endfor
        else
            echoerr 'unreachable'
        endif
        let line += 1
    endwhile
    return graph
endfunction

function! s:find_pred_block(linum) abort
    let sec = s:section_delim_at(a:linum)
    if empty(sec) || sec[0] != s:KIND_BLOCK_PREC && sec[0] != s:KIND_BLOCK_FOLLOW
        throw 'No block is starting at line ' . a:linum
    endif
    if sec[0] != s:KIND_BLOCK_FOLLOW
        throw printf("Block '%s' has no pred block", sec[1])
    endif
    let block_name = '%' . sec[1]
    let pred_block = sec[2][0]

    let graph = s:blocks_graph_at(a:linum)
    if empty(graph)
        throw 'No block is found in function at line ' . a:linum
    endif

    if !has_key(graph, pred_block)
        throw printf("Block '%s' (pred block of '%s') not found in function", pred_block, block_name)
    endif
    return graph[pred_block]
endfunction

function! s:move_to_pred_block() abort
    try
        let b = s:find_pred_block(line('.'))
        call cursor(b.line, col('.'))
    catch
        echohl ErrorMsg | echom v:exception | echohl None
    endtry
endfunction

function! s:find_following_block(linum) abort
    let sec = s:section_delim_at(a:linum)
    if empty(sec) || sec[0] != s:KIND_BLOCK_PREC && sec[0] != s:KIND_BLOCK_FOLLOW
        throw 'No block is starting at line ' . a:linum
    endif
    let block_name = '%' . sec[1]

    let graph = s:blocks_graph_at(a:linum)
    if empty(graph)
        throw 'No block is found in function at line ' . a:linum
    endif

    let follows = graph[block_name].follows
    if empty(follows)
        throw printf("Block '%s' has no following block", block_name)
    endif

    echom printf("Block '%s' has %d following blocks: %s", block_name, len(follows), join(follows, ', '))

    if !has_key(graph, follows[0])
        throw printf("Block '%s' is not defined in function at line %d", follows[0], a:linum)
    endif
    return graph[follows[0]]
endfunction

function! s:move_to_following_block() abort
    try
        let b = s:find_following_block(line('.'))
        call cursor(b.line, col('.'))
    catch
        echohl ErrorMsg | echom v:exception | echohl None
    endtry
endfunction

if !g:llvm_ext_no_mapping
    nnoremap <buffer><silent>[b :<C-u>call <SID>move_to_pred_block()<CR>
    nnoremap <buffer><silent>]b :<C-u>call <SID>move_to_following_block()<CR>
endif

" TODO: Implement 'K' for definition jump
