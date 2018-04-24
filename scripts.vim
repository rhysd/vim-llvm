" This script detects filetype 'llvm' from the content of file.
" See :help new-filetype-scripts

if did_filetype()
    finish
endif

if line('$') > 4
    if getline(1) =~# '^; ModuleID = ' &&
    \  getline(2) =~# '^source_filename = ' &&
    \  getline(3) =~# '^target datalayout = ' &&
    \  getline(4) =~# '^target triple = '
        setfiletype llvm
    endif
endif
