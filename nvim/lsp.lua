local lspconfig = require 'lspconfig'

local function lsp_on_attach(client, bufnr)
  local function buf_set_keymap(...)
    vim.api.nvim_buf_set_keymap(bufnr, ..., { noremap = true, silent = true })
  end

  buf_set_keymap("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>")
  buf_set_keymap("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>")
  buf_set_keymap("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>")
  buf_set_keymap("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>")
  buf_set_keymap("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>")
  -- buf_set_keymap("n", "<space>e", "<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>")
  buf_set_keymap("n", "[d", "<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>")
  buf_set_keymap("n", "]d", "<cmd>lua vim.lsp.diagnostic.goto_next()<CR>")

  -- if client.resolved_capabilities.document_highlight then
  --   vim.api.nvim_exec([[
  --     augroup LspHighlight
  --       autocmd!
  --       autocmd CursorHold  <buffer> lua vim.lsp.buf.document_highlight()
  --       autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
  --       autocmd CursorMovedI <buffer> lua vim.lsp.buf.clear_references()
  --     augroup END
  --   ]], false)
  --   -- autocmd CursorHold  <buffer> lua vim.lsp.buf.hover()
  --   -- autocmd CursorHoldI <buffer> lua vim.lsp.buf.hover()
  -- end
end

lspconfig.rnix.setup {
  cmd = { "@RNIX_PATH@/bin/rnix-lsp" },
  on_attach = lsp_on_attach
}
lspconfig.rust_analyzer.setup {
  cmd = { "@RUST_ANALYZER_PATH@/bin/rust-analyzer" },
  on_attach = lsp_on_attach
}
lspconfig.hls.setup {
  cmd = { "@HLS_PATH@/bin/haskell-language-server-wrapper", "--lsp" },
  cmd_env = {
    -- the wrapper needs to run the correct language server based on ghc version
    PATH = vim.fn.getenv("PATH") .. ":@HLS_PATH@/bin"
  },
  on_attach = lsp_on_attach
}
