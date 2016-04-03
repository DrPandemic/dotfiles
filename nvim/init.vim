" Always show statusline
set laststatus=2

call plug#begin('~/.vim/plugged')

" Navigation
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Plug 'ctrlpvim/ctrlp.vim'
Plug 'mhinz/vim-grepper'
Plug 'bkad/CamelCaseMotion'
Plug 'easymotion/vim-easymotion'
" Tmux
Plug 'christoomey/vim-tmux-navigator'

" Features
Plug 'terryma/vim-multiple-cursors'
Plug 'Shougo/vimproc.vim', { 'do': 'make' }

" Theme
Plug 'junegunn/seoul256.vim'
Plug 'bling/vim-airline'
Plug 'nefo-mi/nyan-modoki.vim'

" Syntax
" Ruby
Plug 'vim-ruby/vim-ruby'
Plug 'tpope/vim-rails'
Plug 'kana/vim-textobj-user'
Plug 'nelstrom/vim-textobj-rubyblock'
Plug 'tmhedberg/matchit'
" Web
Plug 'cakebaker/scss-syntax.vim'
Plug 'Valloric/MatchTagAlways'
Plug 'mattn/emmet-vim'
" JS
Plug 'pangloss/vim-javascript'
Plug 'marijnh/tern_for_vim'
" Elixir
Plug 'elixir-lang/vim-elixir'
" Scala
Plug 'derekwyatt/vim-scala'
" Typescript
Plug 'leafgarland/typescript-vim'

" Linter
Plug 'scrooloose/syntastic'
Plug 'Valloric/YouCompleteMe', { 'do': './install.py --clang-completer --system-libclang --tern-completer' }

" Ctags
Plug 'xolox/vim-misc'
Plug 'xolox/vim-easytags'

Plug 'flowtype/vim-flow'
" Add plugins to &runtimepath
call plug#end()


" REMAP
" Plugins
nmap <silent> <C-E> :NERDTreeToggle<CR>
nnoremap <silent> <C-G> :Grepper -tool git<cr>
nnoremap gF <c-w>gf
let g:multi_cursor_quit_key='<C-c>'
nnoremap <C-c> :call multiple_cursors#quit()<CR>
" Redo
nmap <C-U> :redo<CR>
nmap <silent> <C-R> :CtrlPBufTag<CR>

" Errors
nmap <silent> <C-M> :lprev<CR>
nmap <silent> <C-N> :lnext<CR>

" Save
cnoreabbrev W w
cnoreabbrev Q q
" Default to linux clipboard
set clipboard=unnamedplus

" Dot command
xnoremap . :norm.<CR>

" Macro in visual
xnoremap @ :<C-u>call ExecuteMacroOverVisualRange()<CR>

function! ExecuteMacroOverVisualRange()
  echo "@".getcmdline()
  execute ":'<,'>normal @".nr2char(getchar())
endfunction

" Macro
let @p = 'oimport pdb; pdb.set_trace():w'

" CONFIG
" Swap
set swapfile
set dir=~/tmp

" Visual
" Use 256 colours (Use this setting only if your terminal supports 256 colours)
set t_Co=256
" Unified color scheme (default: dark)
let g:seoul256_background = 234
colo seoul256
set background=dark

set scrolloff=2

" Sidebar
set relativenumber
set number

" Search
set hlsearch
set incsearch
" Whitespaces
highlight ExtraWhitespace ctermbg=red guibg=red
au InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
au InsertLeave * match ExtraWhitespace /\s\+$/

" Indent
set autoindent
set smartindent
set expandtab tabstop=2 shiftwidth=2 smarttab softtabstop=2
set backspace=indent,eol,start

" 80 character line
set colorcolumn=80

" Extensions
au BufNewFile,BufRead *.es6 set filetype=javascript

" Misc
set mouse=nicr
let mapleader=","
filetype plugin on
" Magic speed
set re=1

" PLUGINS
" CtrlP
let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlP'
let g:ctrlp_user_command = ['.git/', 'git --git-dir=%s/.git ls-files -oc --exclude-standard']

" NerdTree
let NERDTreeQuitOnOpen=1

" Tern
let g:tern_map_keys=1
"let g:tern_show_argument_hints='on_hold'

" Omni
set omnifunc=syntaxcomplete#Complete
autocmd CursorMovedI * if pumvisible() == 0|pclose|endif
autocmd InsertLeave * if pumvisible() == 0|pclose|endif

" Syntastic
let g:syntastic_javascript_checkers = ['eslint']
let g:syntastic_javascript_eslint_exec = 'eslint_d'

set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 2
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

let g:syntastic_disabled_filetypes = ['erb', 'rb']
let g:syntastic_ignore_files = ['*.erb', '*.rb']

let g:typescript_compiler_options  = "--experimentalDecorators"

" YCM
let g:ycm_path_to_python_interpreter = '/usr/bin/python3'
let g:ycm_key_list_select_completion = ['<Down>']
autocmd FileType javascript setlocal omnifunc=tern#Complete
let g:ycm_semantic_triggers =  {
            \   'c' : ['->', '.'],
            \   'objc' : ['->', '.'],
            \   'ocaml' : ['.', '#'],
            \   'cpp,objcpp' : ['->', '.', '::'],
            \   'perl' : ['->'],
            \   'php' : ['->', '::', '"', "'", 'use ', 'namespace ', '\'],
            \   'cs,java,javascript,typescript,d,python,perl6,scala,vb,elixir,go' : ['.'],
            \   'html': ['<', '"', '</', ' '],
            \   'vim' : ['re![_a-za-z]+[_\w]*\.'],
            \   'ruby' : ['.', '::'],
            \   'lua' : ['.', ':'],
            \   'erlang' : [':'],
            \   'haskell' : ['.', 're!.']
            \ }
let g:ycm_collect_identifiers_from_tags_files = 1
let g:ycm_global_ycm_extra_conf = '~/.vim/ycm_extra_conf.py'


" Ctags
let g:easytags_languages = {
\   'js': {
\       'cmd': 'jsctags',
\       'args': [],
\       'fileoutput_opt': '-f',
\       'stdout_opt': '-f-',
\       'recurse_flag': '-R'
\   }
\}

" Matchit
runtime macros/matchit.vim

" Line
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#show_buffers = 0
let g:airline_powerline_fonts = 1

" CamelCase
call camelcasemotion#CreateMotionMappings('<leader>') " camel case navigation
