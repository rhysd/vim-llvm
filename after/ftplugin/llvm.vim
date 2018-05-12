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
    let m = matchlist(line, '^\([^:]\+\):\%( \+; preds = %\(.\+\)\)\=$')
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
    let last = line('$')
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

" TODO: Jump to a preceding block if current cursor is on the line of
" block label
