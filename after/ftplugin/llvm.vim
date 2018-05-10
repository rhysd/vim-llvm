if get(g:, 'llvm_extends_official', 1) == 0
    finish
endif

let g:llvm_ext_no_mapping = get(g:, 'llvm_ext_no_mapping', 0)

let s:KIND_BLOCK_PREC = 0
let s:KIND_BLOCK_FOLLOW = 1
let s:KIND_FUNC_BEGIN = 2
let s:KIND_FUNC_END = 3

function! s:section_start(lnum) abort
    let line = getline(a:lnum)
    let m = matchlist(line, '^\([^:]\+\):\%( \+; preds = %\(.\+\)\)\=$')
    if !empty(m)
        if m[2] ==# ''
            return [s:KIND_BLOCK_PREC, m[1]]
        else
            return [s:KIND_BLOCK_FOLLOW, m[1], m[2]]
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

function! s:next_section(stop_func_begin) abort
    let func_delim = a:stop_func_begin ? s:KIND_FUNC_BEGIN : s:KIND_FUNC_END
    let last = line('$')
    let line = line('.')
    while line < last
        let line += 1
        let sec = s:section_start(line)
        if empty(sec)
            continue
        endif
        let kind = sec[0]
        if kind == s:KIND_BLOCK_PREC || kind == s:KIND_BLOCK_FOLLOW || kind == func_delim
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
        let sec = s:section_start(line)
        if empty(sec)
            continue
        endif
        let kind = sec[0]
        if kind == s:KIND_BLOCK_PREC || kind == s:KIND_BLOCK_FOLLOW || kind == func_delim
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
