Vim files for Low Level Virtual Machine (LLVM)
==============================================

This repository and its subdirectories contain source code for Vim files for the Low Level Virtual
Machine, a toolkit for the construction of highly optimized compilers, optimizers, and runtime
environments. LLVM is open source software. You may freely distribute it under the terms of the license
agreement found in LICENSE.txt.

This repository aims to make Vim plugin package managers deal with a Vim plugin bundled in the LLVM
official repository and provides some extended features.

If no license is specified in the header of a file (it means that it came from LLVM official repository),
the file is distributed under the license described in [LICENSE.txt](LICENSE.txt).

## Imported from upstream (LLVM official repository)

Following files are imported from `llvm/utils/vim`. They are updated at LLVM version bump.

- `ftdetect/*.vim`
- `ftplugin/*.vim`
- `indent/*.vim`
- `syntax/*.vim`

## Extended features

This repository provides some advanced features which are not supported in LLVM official repository.

- `after/**/*.vim`: Extended filetype support
- `scripts.vim`: Improved `llvm` filetype detection

Some useful mappings to jump among basic blocks are provided.

- `]]`, `][`: Move the cursor to the next basic block (Please see `:help ]]` for more details).
- `b]`: Jump to a basic block which follows the current basic block.
- `b[`: Jump to a basic block which the current basic block is following.

More mappings will be supported (under construction).

If you want to disable this feature, you write a config in your `vimrc`:

```vim
let g:llvm_extends_official = 0
```

## Installation

Please choose one of follows:

- Use your favorite plugin manager like [vim-plug](https://github.com/junegunn/vim-plug), [dein.vim](https://github.com/Shougo/dein.vim), [minpac](https://github.com/k-takata/minpac).
- Use `:packadd` (Please seee `:help packadd` for more details).
- Copy all directories and `scripts.vim` to your `~/.vim` (or `~/vimfiles` on Windows) manually. (not recommended)
