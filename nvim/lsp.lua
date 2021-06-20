local lspconfig = require 'lspconfig'

local function lsp_on_attach(client)
  if client.resolved_capabilities.document_highlight then
    vim.api.nvim_exec([[
      augroup LspHighlight
        autocmd CursorHold  <buffer> lua vim.lsp.buf.document_highlight()
        autocmd CursorHoldI <buffer> lua vim.lsp.buf.document_highlight()
        autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
      augroup END
    ]], false)
  end
end

lspconfig.rnix.setup {
  cmd = { "@RNIX_PATH@" },
  on_attach = lsp_on_attach
}
lspconfig.rust_analyzer.setup {
  cmd = { "@RUST_ANALYZER_PATH@" },
  on_attach = lsp_on_attach
}
lspconfig.hls.setup {
  cmd = { "@HLS_PATH@", "--lsp" },
  on_attach = lsp_on_attach
}
