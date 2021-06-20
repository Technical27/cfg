local lspconfig = require 'lspconfig'

local function lsp_on_attach(client)
  if client.resolved_capabilities.document_highlight then
    vim.api.nvim_exec([[
      augroup LspHighlight
        autocmd!
        autocmd CursorHold  <buffer> lua vim.lsp.buf.document_highlight()
        autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
        autocmd CursorMovedI <buffer> lua vim.lsp.buf.clear_references()
      augroup END
    ]], false)
    -- autocmd CursorHold  <buffer> lua vim.lsp.buf.hover()
    -- autocmd CursorHoldI <buffer> lua vim.lsp.buf.hover()
  end
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
