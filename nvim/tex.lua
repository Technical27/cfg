vim.opt_local.spell = true
vim.opt_local.spelllang = "en_us"

require('cmp').setup.buffer {
  sources = {
    { name = 'luasnip' },
    { name = 'spell' },
  },
}
