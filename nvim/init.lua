require('packer').startup(function()
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'


  -- Syntax plugins
  use 'sheerun/vim-polyglot'
  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate',
    requires = { 'JoosepAlviste/nvim-ts-context-commentstring' },
    config = function()
      require('nvim-treesitter.configs').setup {
        indent = {
          enable = true
        },
        highlight = {
          enable = true,
          disable = { "tex", "latex" }
        },
        context_commentstring = {
          enable = true
        }
      }

      vim.o.foldmethod = 'expr'
      vim.cmd 'set foldexpr=nvim_treesitter#foldexpr()'
    end
  }

  use 'gruvbox-community/gruvbox'
  use {
    'neovim/nvim-lspconfig',
    config = function() require('config.lsp') end
  }
 
  use {
    'nvim-telescope/telescope.nvim',
    requires = { { 'nvim-lua/popup.nvim' }, { 'nvim-lua/plenary.nvim' } },
    config = function()
      local telescope = require('telescope.builtin')

      vim.keymap.set('n', '<C-p>', telescope.find_files, { noremap = true })
      vim.keymap.set('n', '<C-d>', telescope.diagnostics, { noremap = true })

      vim.keymap.set('n', '<C-t>', '<cmd>TodoTelescope<cr>', { noremap = true })

      vim.lsp.handlers["textDocument/definition"] = telescope.lsp_definitions
      vim.lsp.handlers["textDocument/implementation"] = telescope.lsp_implementation
      vim.lsp.handlers["textDocument/typeDefinition"] = telescope.lsp_type_definitions
      vim.lsp.handlers["textDocument/references"] = telescope.lsp_references
      vim.lsp.handlers["textDocument/documentSymbols"] = telescope.lsp_document_symbols
      vim.lsp.handlers["workspace/symbol"] = telescope.lsp_workspace_symbols
    end
  }

  use 'farmergreg/vim-lastplace'
  use 'jghauser/mkdir.nvim'
  use 'gpanders/editorconfig.nvim'
  use 'ggandor/lightspeed.nvim'
  use {
    'windwp/nvim-autopairs',
    requires = { 'hrsh7th/nvim-cmp' },
    config = function()
      require('nvim-autopairs').setup()

      local cmp_autopairs = require('nvim-autopairs.completion.cmp')
      local cmp = require('cmp')
      cmp.event:on(
        'confirm_done',
        cmp_autopairs.on_confirm_done()
      )
    end,
  }

  use 'tpope/vim-fugitive'
  use 'tpope/vim-commentary'
  use 'tpope/vim-surround'
  use 'tpope/vim-repeat'
  use 'tpope/vim-sexp-mappings-for-regular-people'

  use 'guns/vim-sexp'

  -- Visuals
  use {
    'kyazdani42/nvim-web-devicons',
    config = function() require('nvim-web-devicons').setup {} end
  }
  use {
    'windwp/windline.nvim',
    config = function() require('config.statusline') end
  }
  use {
    'noib3/nvim-cokeline',
    config = function() require('config.bufferline') end
  }

  use {
    'lewis6991/gitsigns.nvim',
    requires = { 'nvim-lua/plenary.nvim' },
    config = function() require('gitsigns').setup {} end
  }
  
  -- this is it
  -- use {
  --   'folke/todo-comments.nvim',
  --   requires = 'nvim-lua/plenary.nvim',
  --   config = function() require('todo-comments').setup {} end
  -- }

  use {
    'hrsh7th/nvim-cmp',
    requires = { 'L3MON4D3/LuaSnip' },
    config = function() require('config.cmp') end
  }

  use 'hrsh7th/cmp-buffer'
  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/cmp-path'
  use 'f3fora/cmp-spell'
  use 'saadparwaiz1/cmp_luasnip'
  use { 'tzachar/cmp-tabnine', run = './install.sh', requires = 'hrsh7th/nvim-cmp' }

  use {
   'L3MON4D3/LuaSnip',
    requires = {
      'rafamadriz/friendly-snippets',
    },
    config = function() require('luasnip/loaders/from_vscode').lazy_load() end
  }

  use {
    'mbbill/undotree',
    config = function() vim.keymap.set('n', '<C-u>', '<cmd>UndotreeToggle<cr>', { noremap = true }) end
  }

  use 'ThePrimeagen/vim-be-good'

  use {
    'leafOfTree/vim-svelte-plugin',
    ft = 'svelte',
    config = function()
      vim.g.vim_svelte_plugin_load_full_syntax = 1
    end
  }

  use {
    'lervag/vimtex',
    -- can't use for inverse search to work
    -- ft = {'tex', 'latex'},
    requires = { 'hrsh7th/nvim-cmp' },
    config = function()
      vim.g.tex_flavor = 'latex'
      vim.g.vimtex_compiler_method = 'latexmk'
      vim.g.vimtex_quickfix_mode = 0
      vim.g.vimtex_view_method = 'zathura'
    end
  }

  use 'vimwiki/vimwiki'
end)

vim.o.termguicolors = true
vim.o.showmode = false

vim.g.gruvbox_italic = 1

vim.o.background = 'dark'

vim.o.number = true
vim.o.backup = false
vim.o.writebackup = false
vim.o.updatetime = 2000
vim.opt.shortmess:append('c')
vim.o.inccommand = 'nosplit'
vim.o.completeopt='menuone,preview,noselect'
vim.o.signcolumn = 'yes'
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.smartindent = true
vim.o.infercase = true
vim.o.title = true
vim.o.virtualedit = 'block'
vim.o.foldnestmax = 10
vim.o.foldenable = false
vim.o.lazyredraw = true
vim.o.synmaxcol = 250
vim.o.linebreak = true
vim.o.cursorline = true
vim.o.cursorlineopt = "number"

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

vim.cmd [[
  source /home/aamaruvi/.config/nvim/ts.vim
  filetype plugin indent on
  colorscheme gruvbox

  augroup Buffer
    autocmd!
    autocmd BufWritePre * lua vim.lsp.buf.format({ async = false })
    autocmd BufRead,BufNewfile flake.lock,project.pros set filetype=json
  augroup END
]]
