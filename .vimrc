" set cindent
set paste
"set foldmethod=indent
" Wrap too long lines
set wrap

" Tabs are 2 characters
set tabstop=2

" (Auto)indent uses 2 characters
set shiftwidth=2

" spaces instead of tabs
set expandtab

" guess indentation
set autoindent

" Expand the command line using tab
set wildchar=<Tab>

" show line numbers
" set number

set foldmethod=indent

" enable all features
set nocompatible

" powerful backspaces
set backspace=indent,eol,start

" highlight the searchterms
set hlsearch

" jump to the matches while typing
set incsearch

" ignore case while searching
" set ignorecase

" don't wrap words
set textwidth=0

" history
set history=50

" 1000 undo levels
set undolevels=1000

" show a ruler
set ruler

" show partial commands
set showcmd

" show matching braces
set showmatch

" write before hiding a buffer
set autowrite

" auto-detect the filetype
filetype plugin indent on

" syntax highlight
syntax on

" Always show the menu, insert longest match
set completeopt=menuone,longest

" When editing a file, always jump to the last known cursor position.
" Don't do it when the position is invalid or when inside an event handler
" (happens when dropping a file on gvim).
autocmd BufReadPost *
  \ if line("'\"") > 0 && line("'\"") <= line("$") |
  \   exe "normal g`\"" |
  \ endif

