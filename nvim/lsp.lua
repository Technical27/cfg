local lspconfig = require 'lspconfig'

local function lsp_on_attach(client, bufnr)
  local function buf_set_keymap(mode, key, cmd)
    vim.api.nvim_buf_set_keymap(bufnr, mode, key, cmd, { noremap = true, silent = true })
  end

  buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>')
  buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>')
  buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>')
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>')
  buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>')
  buf_set_keymap('n', 'gR', '<cmd>lua vim.lsp.buf.rename()<CR>')
  buf_set_keymap('n', 'gC', '<cmd>lua vim.lsp.buf.code_action()<CR>')
  buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>')
  buf_set_keymap('n', 'ge', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>')
  buf_set_keymap('n', '[g', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>')
  buf_set_keymap('n', ']g', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>')
end

lspconfig.rnix.setup {
  cmd = { "@RNIX_PATH@/bin/rnix-lsp" },
  on_attach = lsp_on_attach
}
lspconfig.rust_analyzer.setup {
  cmd = { "@RUST_ANALYZER_PATH@/bin/rust-analyzer" },
  on_attach = lsp_on_attach
}
lspconfig.clojure_lsp.setup {
  cmd = { "@CLOJURE_LSP_PATH@/bin/clojure-lsp" },
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
lspconfig.svelte.setup {
  cmd = { "@SVELTE_LANGUAGE_SERVER_PATH@/bin/svelteserver", "--stdio" },
  on_attach = lsp_on_attach
}

lspconfig.tsserver.setup {
  cmd = { "@TSSERVER_PATH@/bin/typescript-language-server", "--stdio" },
  cmd_env = {
    PATH = vim.fn.getenv("PATH") .. ":@TYPESCRIPT@/bin"
  },
  on_attach = lsp_on_attach
}

lspconfig.jdtls.setup {
  cmd = { "/home/aamaruvi/.local/share/jdt/launch.sh" },
  cmd_env = {
    JAVA_HOME = '/home/aamaruvi/wpilib/2021/jdk/',
    WORKSPACE = '/home/aamaruvi/wpilib/2021/jdt/workspace/',
    GRADLE_HOME = '/home/aamaruvi/wpilib/2021/'
  }
}

lspconfig.ccls.setup {
  cmd = { "@CCLS_PATH@/bin/ccls" },
  on_attach = lsp_on_attach
}
