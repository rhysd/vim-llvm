autocmd BufNew,BufReadPost *.ll setlocal filetype=llvm

function! s:set_ft()
    if did_filetype() || line('$') < 3
        return
    endif

    if getline(1) =~# '^; ModuleID = ' && getline(2) =~# '^target datalayout = ' && getline(3) =~# '^target triple = '
        setfiletype llvm
    endif
endfunction

autocmd BufNew,BufReadPost,VimEnter * call s:set_ft()
