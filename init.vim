let g:gruvbox_sign_column = 'fg0'
let g:gruvbox_italic = 1

fun g:LoadColors()
  hi! clear SignColumn

  " all the treesitter highlights
  hi! link TSAnnotation GruvboxAqua
  hi! link TSBoolean GruvboxPurple
  hi! link TSCharacter GruvboxPurple
  hi! TSComment gui=italic guifg=GruvboxGrey
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
  echo "failed to read theme file"
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

" nvim-treesitter setup
set foldmethod=expr
set foldexpr=nvim_treesitter#foldexpr()
lua <<EOF
require'nvim-treesitter.configs'.setup {
  indent = {
    enable = true
  },
  highlight = {
    enable = true
  }
}
EOF

let g:tex_flavor             = 'latex'
let g:vimtex_compiler_method = 'tectonic'
let g:vimtex_view_method     = 'zathura'
let g:vimtex_quickfix_mode   = 0

let g:lion_squeeze_spaces = 1

let g:airline#extensions#tabline#enabled     = 1
let g:airline#extensions#nvimlsp#enabled     = 0
let g:airline#extensions#tabline#tab_nr_type = 1
let g:airline_powerline_fonts                = 1
let g:airline#extensions#tabline#formatter   = 'unique_tail_improved'

let g:coc_snippet_next = '<TAB>'
let g:coc_snippet_prev = '<S-TAB>'

let g:EasyMotion_smartcase = 1

let g:coc_fzf_opts = ['--color=16']

function! Fzf_dev() abort
  let s:fzf_command = 'rg --files --hidden --follow --glob "!{.git,build,node_modules,target}"'
  let s:bat_command = 'bat --style=numbers,changes --color always {2..-1} | head -'.float2nr((&lines * 0.4) - 2)

  function! s:get_open_files() abort
    let l:buffers = map(filter(copy(getbufinfo()), 'v:val.listed'), 'v:val.name')
    let l:len = len(fnamemodify(".", ":p"))
    return map(l:buffers, 'v:val[l:len:]')
  endf

  function! s:files() abort
    let l:buffers = s:get_open_files()
    let l:files = filter(split(system(s:fzf_command), '\n'), 'index(l:buffers, v:val) == -1')
    return s:prepend_icon(l:files)
  endf

  function! s:prepend_icon(candidates) abort
    let l:result = []
    for l:candidate in a:candidates
      if filereadable(l:candidate)
        let l:filename = fnamemodify(l:candidate, ':p:t')
        let l:icon = WebDevIconsGetFileTypeSymbol(l:filename, isdirectory(l:filename))
        call add(l:result, printf('%s %s', l:icon, l:candidate))
      endif
    endfor

    return l:result
  endf

  function! s:edit_file(item) abort
    let l:pos = stridx(a:item, ' ')
    let l:file_path = a:item[pos+1:-1]
    execute 'silent e' l:file_path
  endf

 call fzf#run({
       \ 'source' : <sid>files(),
       \ 'sink'   : function('s:edit_file'),
       \ 'options': '--color 16 -m --preview "'.s:bat_command.'"',
       \ 'down'   : '40%' })
endf

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
nmap <silent> ]g <Plug>(coc-diagnostic-next)

nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

nnoremap <silent> T :bprev<CR>
nnoremap <silent> Y :bnext<CR>

nnoremap <C-u> :UndotreeToggle<CR>

nnoremap <silent> <C-p> :call Fzf_dev()<CR>

inoremap <silent><expr> <c-space> coc#refresh()
inoremap <expr> <CR> complete_info()["selected"] != "-1" ? "\<C-y>" : "\<C-g>u\<CR>"
nnoremap <silent> K :call <SID>show_documentation()<CR>

fun! g:ClearSearch()
  let @/ = ""
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
