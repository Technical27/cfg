vim.opt_local.spell = true
vim.opt_local.spellfile = true

require('cmp').setup.buffer {
  sources = {
    { name = 'luasnip' },
    { name = 'spell' },
  },
}
