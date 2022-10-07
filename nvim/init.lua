require('packer').startup(function()
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'

  use 'sheerun/vim-polyglot'

  use {
   'nvim-treesitter/nvim-treesitter',
    config = function()
      require('nvim-treesitter.configs').setup {
        indent = {
          enable = true
        },
        highlight = {
          enable = true
        }
      }

      vim.o.foldmethod = 'expr'
      vim.cmd 'set foldexpr=nvim_treesitter#foldexpr()'
    end
  }

  use {
    'nvim-telescope/telescope.nvim',
    requires = { { 'nvim-lua/popup.nvim' }, { 'nvim-lua/plenary.nvim' } }
  }

  use 'gruvbox-community/gruvbox'

  use 'farmergreg/vim-lastplace'

  use {
    'windwp/nvim-autopairs',
    config = function()
      require('nvim-autopairs').setup()
    end,
  }

  use {
    'neovim/nvim-lspconfig',
    config = function() require('lsp') end
  }

  use 'tpope/vim-fugitive'
  use 'tpope/vim-commentary'
  use 'tpope/vim-surround'
  use 'tpope/vim-repeat'
  use 'tpope/vim-sexp-mappings-for-regular-people'

  use 'guns/vim-sexp'

  use 'ryanoasis/vim-devicons'
  use 'vim-airline/vim-airline'

  use {
    'lewis6991/gitsigns.nvim',
    requires = { 'nvim-lua/plenary.nvim' },
    config = function() require('gitsigns').setup {} end
  }

  use {
    'folke/todo-comments.nvim',
    requires = 'nvim-lua/plenary.nvim',
    config = function() require('todo-comments').setup {} end
  }

  use {
    'gbrlsnchs/telescope-lsp-handlers.nvim',
    requires = 'nvim-telescope/telescope.nvim',
    config = function() require('telescope').load_extension('lsp_handlers') end
  }

  use 'hrsh7th/nvim-cmp'
  use 'hrsh7th/cmp-buffer'
  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/cmp-path'
  use 'f3fora/cmp-spell'
  use { 'tzachar/cmp-tabnine', run = './install.sh', requires = 'hrsh7th/nvim-cmp' }

  use {
   'L3MON4D3/LuaSnip',
    requires = {
      'rafamadriz/friendly-snippets',
    },
    config = function() require('luasnip/loaders/from_vscode').lazy_load() end
  }

  use 'mbbill/undotree'

  use 'saadparwaiz1/cmp_luasnip'

  use 'ThePrimeagen/vim-be-good'

  use 'leafOfTree/vim-svelte-plugin'

  use 'lervag/vimtex'

  use 'vimwiki/vimwiki'
end)

vim.o.fillchars = 'fold: '

-- nvim-cmp setup
local cmp = require('cmp')
local luasnip = require('luasnip')
cmp.setup {
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = {
    ['<C-n>'] = function(fallback)
        if cmp.visible() then
            cmp.select_next_item()
        elseif luasnip.jumpable(1) then
            vim.fn.feedkeys(vim.api.nvim_replace_termcodes('<Plug>luasnip-jump-next', true, true, true), '')
        else
            fallback()
        end
    end,
    ['<C-p>'] = function(fallback)
        if cmp.visible() then
            cmp.select_prev_item()
        elseif luasnip.jumpable(-1) then
            vim.fn.feedkeys(vim.api.nvim_replace_termcodes('<Plug>luasnip-jump-prev', true, true, true), '')
        else
            fallback()
        end
    end,
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.close(),
    ['<CR>'] = cmp.mapping.confirm {
      select = true,
    },
  },
  sources = {
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
    { name = 'cmp_tabnine' },
    { name = 'path' },
    { name = 'buffer' },
  },
}


vim.g['airline#extensions#tabline#enabled'] = 1
vim.g['airline#extensions#nvimlsp#enabled'] = 1
vim.g['airline#extensions#tabline#tab_nr_type'] = 1
vim.g['airline_powerline_fonts'] = 1
vim.g['airline#extensions#tabline#formatter'] = 'unique_tail_improved'

vim.g.tex_flavor = 'latex'
vim.g.vimtex_compiler_method = 'tectonic'
vim.g.vimtex_quickfix_mode = 0
vim.g.vimtex_view_method = 'zathura'

function _G.tex_settings()
  vim.opt_local.spell = true
  cmp.setup.buffer {
    sources = {
      { name = 'luasnip' },
      { name = 'spell' },
    },
  }
end

vim.api.nvim_set_keymap('n', 'T', '<cmd>bprev<cr>', { noremap = true })
vim.api.nvim_set_keymap('n', 'Y', '<cmd>bnext<cr>', { noremap = true })

vim.g.vim_svelte_plugin_load_full_syntax = 1

vim.o.termguicolors = true
vim.o.showmode = false

vim.g.gruvbox_italic = 1

vim.o.background = 'dark'

vim.o.number = true
vim.o.hidden = true
vim.o.backup = false
vim.o.writebackup = false
vim.o.updatetime = 200
vim.opt.shortmess:append('c')
vim.o.inccommand = 'nosplit'
vim.o.completeopt='menu,menuone,noselect'
vim.o.signcolumn = 'yes'
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.title = true
vim.o.foldnestmax = 10
vim.o.foldenable = false
vim.o.lazyredraw = true
vim.o.synmaxcol = 500

vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.expandtab = true

vim.o.breakindent = true

vim.o.mouse = 'a'
vim.o.showmatch = true
vim.o.undofile = true
vim.o.grepprg = 'rg --vimgrep'
vim.o.autoindent = true

vim.o.clipboard = 'unnamedplus'

vim.o.incsearch = true
vim.o.hlsearch = true

vim.api.nvim_set_keymap('n', '<C-p>', '<cmd>Telescope find_files<cr>', { noremap = true })
vim.api.nvim_set_keymap('n', '<C-o>', '<cmd>Telescope buffers<cr>', { noremap = true })
vim.api.nvim_set_keymap('n', '<C-t>', '<cmd>TodoTelescope<cr>', { noremap = true })
vim.api.nvim_set_keymap('n', '<C-u>', '<cmd>UndotreeToggle<cr>', { noremap = true })

function _G.clear_whitespace()
  if not vim.b.noclear then
    local save = vim.fn.winsaveview()
    vim.cmd [[%s/\\\@<!\s\+$//e]]
    vim.fn.winrestview(save)
  end
end

vim.api.nvim_exec([[
  colorscheme gruvbox
  filetype plugin indent on

  source /home/aamaruvi/.config/nvim/ts.vim

  augroup Latex
    autocmd!
    autocmd FileType tex call v:lua.tex_settings()
  augroup END

  augroup Buffer
    autocmd!
    autocmd BufWritePre * call v:lua.clear_whitespace()
    autocmd BufWritePre * lua vim.lsp.buf.format({ async = false })
    autocmd BufRead,BufNewfile flake.lock,project.pros set filetype=json
  augroup END
]], false)
