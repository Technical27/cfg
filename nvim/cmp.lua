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
