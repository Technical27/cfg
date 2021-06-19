let g:gruvbox_sign_column = 'fg0'
let g:gruvbox_italic = 1

fun g:LoadColors()
  hi! clear SignColumn

  " all the treesitter highlights
  hi! link TSAnnotation GruvboxAqua
  hi! link TSBoolean GruvboxPurple
  hi! link TSCharacter GruvboxPurple
  hi! TSComment gui=italic guifg=GruvboxGray
  hi! link TSConstructor GruvboxOrange
  hi! link TSConditional GruvboxRed
  hi! link TSConstant GruvboxPurple
  hi! link TSConstBuiltin GruvboxOrange
  hi! link TSConstMacro GruvboxAqua
  hi! link TSError GruvboxRed
  hi! link TSException GruvboxRed
  hi! link TSField GruvboxBlue
  hi! link TSFloat GruvboxPurple
  hi! link TSFunction GruvboxGreenBold
  hi! link TSFuncBuiltin GruvboxOrange
  hi! link TSFuncMacro GruvboxAqua
  hi! link TSInclude GruvboxAqua
  hi! link TSKeyword GruvboxRed
  hi! link TSLabel GruvboxRed
  hi! link TSMethod GruvboxGreenBold
  hi! link TSNamespace GruvboxAqua
  hi! clear TSNone
  hi! link TSNumber GruvboxPurple
  hi! link TSOperator GruvboxFg1
  hi! link TSParamter GruvboxBlue
  hi! link TSParameterReferance TSParameter
  hi! link TSProperty GruvboxBlue
  hi! link TSPunctDelimiter GruvboxFg
  hi! link TSPunctBracket GruvboxFg
  hi! link TSPunctSpecial GruvboxFg
  hi! link TSRepeat GruvboxRed
  hi! link TSString GruvboxGreen
  hi! link TSStringRegex GruvboxYellow
  hi! link TSStringEscape GruvboxOrange
  hi! link TSTag GruvboxRed
  hi! link TSTagDelimiter GruvboxFg
  hi! link TSText TSNone
  hi! link TSLiteral GruvboxGreen
  hi! TSURI gui=underline guifg=GruvboxAqua
  hi! link TSType GruvboxYellow
  hi! link TSTypeBuiltin GruvboxYellow
  hi! link TSVariable GruvboxFg
  hi! TSEmphasis gui=italic
  hi! TSUnderline gui=underline
endf

augroup Color
  autocmd!
  autocmd ColorScheme * call g:LoadColors()
augroup end

colorscheme gruvbox

let s:theme_file = glob("~/.config/nvim/theme")

if (filereadable(s:theme_file))
  let &background = readfile(s:theme_file)[0]
else
  echom "failed to read theme file"
  set background=dark
endif

set number
set hidden
set nobackup
set nowritebackup
set updatetime=100
set shortmess+=c
set signcolumn=yes
set ignorecase
set smartcase
set title
set foldnestmax=10
set nofoldenable
set lazyredraw
set synmaxcol=180
set tabstop=2
set shiftwidth=2
set linebreak
set expandtab
set clipboard=unnamedplus
set termguicolors
set showmatch
set mouse=a
set undofile
set grepprg="rg --vimgrep"
set noshowmode
set autoindent

" nvim-treesitter setup
set foldmethod=expr
set foldexpr=nvim_treesitter#foldexpr()

source late.lua

let g:tex_flavor             = 'latex'
let g:vimtex_compiler_method = 'tectonic'
let g:vimtex_view_method     = 'zathura'
let g:vimtex_quickfix_mode   = 0
let g:vimtex_fold_enabled    = 1

let g:lion_squeeze_spaces = 1

" let g:airline#extensions#tabline#enabled     = 1
" let g:airline#extensions#nvimlsp#enabled     = 0
" let g:airline#extensions#tabline#tab_nr_type = 1
" let g:airline_powerline_fonts                = 1
" let g:airline#extensions#tabline#formatter   = 'unique_tail_improved'

let g:coc_snippet_next = '<TAB>'
let g:coc_snippet_prev = '<S-TAB>'

let g:EasyMotion_smartcase = 1

nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:check_back_space() abort
  let l:col = col('.') - 1
  return !l:col || getline('.')[l:col - 1]  =~# '\s'
endf

function! s:show_documentation() abort
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endf

" clear whitespace on save
function! TrimWhitespace() abort
  let l:save = winsaveview()
  %s/\\\@<!\s\+$//e
  call winrestview(l:save)
endf

nmap <silent> [g <Plug>(coc-diagnostic-prev)

nnoremap <silent> gd <cmd>Telescope coc definitions
nnoremap <silent> gy <cmd>Telescope coc type_definitions
nnoremap <silent> gi <cmd>Telescope coc implementations
nnoremap <silent> gr <cmd>Telescope coc references
nnoremap <silent> gw <Plug>(coc-rename)

nnoremap <silent> T :bprev<CR>
nnoremap <silent> Y :bnext<CR>

nnoremap <C-u> :UndotreeToggle<CR>

nnoremap <C-p> <cmd>Telescope find_files<CR>

inoremap <silent><expr> <c-space> coc#refresh()
inoremap <expr> <CR> complete_info()["selected"] != "-1" ? "\<C-y>" : "\<C-g>u\<CR>"

fun! g:ClearSearch()
  let l:save = winsaveview()
  let @/ = ""
  call winrestview(l:save)
endf

nnoremap <silent><expr> <ESC> g:ClearSearch()

" I will probably never record a macro
nnoremap q <nop>

augroup Buffer
  autocmd!
  autocmd BufWritePre * call TrimWhitespace()
  autocmd CursorHold * silent call CocActionAsync('highlight')
augroup end

nmap <Leader>j <Plug>(easymotion-j)
nmap <Leader>k <Plug>(easymotion-k)
nmap f <Plug>(easymotion-s)
nmap w <Plug>(easymotion-w)
nmap e <Plug>(easymotion-e)
nmap b <Plug>(easymotion-b)

augroup EasyMotion
  autocmd!
  autocmd User EasyMotionPromptBegin silent! CocDisable
  autocmd User EasyMotionPromptEnd silent! CocEnable
augroup END

augroup Goyo
  autocmd!
  autocmd User GoyoEnter Limelight
  autocmd User GoyoLeave Limelight!
augroup END
