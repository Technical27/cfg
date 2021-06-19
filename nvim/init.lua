require('packer').startup(function()
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'

  use 'sheerun/vim-polyglot'

  use 'nvim-treesitter/nvim-treesitter'

  use {
      'nvim-telescope/telescope.nvim',
      requires = {{'nvim-lua/popup.nvim'}, {'nvim-lua/plenary.nvim'}}
    }

  use 'gruvbox-community/gruvbox'

  use 'farmergreg/vim-lastplace'

  use 'cohama/lexima.vim'

  use {
  'glepnir/galaxyline.nvim',
    branch = 'main',
    config = function() require 'statusline' end,
    requires = {'kyazdani42/nvim-web-devicons', opt = true}
  }

  use 'neovim/nvim-lspconfig'

  use 'hrsh7th/nvim-compe'

  use 'tpope/vim-commentary'

  use {'lewis6991/gitsigns.nvim', requires = {'nvim-lua/plenary.nvim'} }

  use 'hrsh7th/vim-vsnip'
  use 'rafamadriz/friendly-snippets'
end)

vim.api.nvim_command('source ' .. vim.fn.glob('~/.config/nvim/ts.vim'))

vim.g.lexima_no_default_rules = true
vim.fn['lexima#set_default_rules']()

vim.api.nvim_command('filetype plugin indent on')

require 'nvim-treesitter.configs'.setup {
  indent = {
    enable = true
  },
  highlight = {
    enable = true
  }
}

require 'compe'.setup {
  enabled = true,
  autocomplete = true,
  debug = false,
  min_length = 1,
  preselect = 'always',
  throttle_time = 80,
  source_timeout = 200,
  incomplete_delay = 400,
  max_abbr_width = 100,
  max_kind_width = 100,
  max_menu_width = 100,
  documentation = true,

  source = {
    path = true,
    buffer = {kind = "﬘", true},
    vsnip = {kind = "﬌"},
    nvim_lsp = true,
  },
}

-- local telescope = require 'telescope'
-- telescope.load_extension('coc')

-- require('bufferline').setup {
--     oions = {
--         show_close_icon = false,
--         show_buffer_close_icons = false,
--         modified_icon = nil
--     },
--     highlights = {
--         fill = {
--             guibg = {
--                 attribute = 'fg',
--                 highlight = 'GruvboxBg1'
--             }
--         }
--     }
-- }

local lspconfig = require 'lspconfig'

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true
capabilities.textDocument.completion.completionItem.resolveSupport = {
  properties = {
    'documentation',
    'detail',
    'additionalTextEdits',
  }
}

local t = function(str)
    return vim.api.nvim_replace_termcodes(str, true, true, true)
end

local check_back_space = function()
    local col = vim.fn.col(".") - 1
    return col == 0 or vim.fn.getline("."):sub(col, col):match("%s")
end

_G.snip_next = function()
  if vim.fn.call("vsnip#available", {1}) == 1 then
    return t "<Plug>(vsnip-expand-or-jump)"
  else
    return t "<Tab>"
  end
end

_G.snip_prev = function()
  if vim.fn.call("vsnip#jumpable", {-1}) == 1 then
    return t "<Plug>(vsnip-jump-prev)"
  else
    return t "<S-Tab>"
  end
end

_G.compe_complete = function()
  return vim.fn["compe#confirm"](vim.fn['lexima#expand'](t '<CR>', 'i'))
end

vim.api.nvim_set_keymap("i", "<Tab>", "v:lua.snip_next()", {expr = true})
vim.api.nvim_set_keymap("i", "<S-Tab>", "v:lua.snip_prev()", {expr = true})
vim.api.nvim_set_keymap("i", "<CR>", "v:lua.compe_complete()", {expr = true})
-- _G.snip_comp = function()
--   if vim.fn.pumvisible() == 1 then
--     return vim.fn['compe#complete']()
--   else
--     return t "<CR>"
--   end
-- end
--

lspconfig.rnix.setup {}
lspconfig.rust_analyzer.setup {
  capabilities = capabilites
}

vim.o.termguicolors = true
vim.o.showmode = false

-- vim.g.gruvbox_sign_column = 'fg0'
vim.g.gruvbox_italic = 1

vim.cmd('colorscheme gruvbox')

local theme_file = vim.fn.glob('~/.config/nvim/theme')

if vim.fn.filereadable(theme_file) then
    vim.o.background = vim.fn.readfile(theme_file)[1]
else
    print('failed to load theme file')
    vim.o.background = 'dark'
end

vim.o.number = true
vim.o.hidden = true
vim.o.backup = false
vim.o.writebackup = false
vim.o.updatetime = 200
vim.opt.shortmess:append('c')
vim.o.inccommand = 'nosplit'
vim.o.completeopt='menuone,noselect'
vim.o.signcolumn = 'yes'
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.title = true
vim.o.foldnestmax = 10
vim.o.foldenable = false
vim.o.lazyredraw = true
vim.o.synmaxcol = 180

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

vim.o.foldmethod = 'expr'
vim.o.foldexpr = vim.fn['nvim_treesitter#foldexpr']()
vim.g.EasyMotion_smartcase = 1

vim.api.nvim_set_keymap('n', '<C-p>', '<cmd>Telescope find_files<cr>', { noremap = true })

function _G.clear_whitespace()
  local save = vim.fn.winsaveview()
  vim.api.nvim_command([[%s/\\\@<!\s\+$//e]])
  vim.fn.winrestview(save)
end

vim.api.nvim_exec([[
  augroup Buffer
    autocmd!
    autocmd BufWritePre * call v:lua.clear_whitespace()
  augroup END
]], false)
