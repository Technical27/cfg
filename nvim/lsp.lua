local lspconfig = require('lspconfig')

local function lsp_on_attach(client, bufnr)
  local function keymap(mode, key, f)
    vim.keymap.set(mode, key, f, { noremap = true, silent = true, buffer = bufnr })
  end

  local caps = client.server_capabilities;

  -- keymap('n', '<space>D', vim.lsp.buf.type_definition)
  if caps.declarationProvider then
    keymap('n', 'gD', vim.lsp.buf.declaration)
  end

  if caps.definitionProvider then
    keymap('n', 'gd', vim.lsp.buf.definition)
  end

  if caps.hoverProvider then
    keymap('n', 'K', vim.lsp.buf.hover)
  end

  if caps.renameProvider then
    keymap('n', 'gR', vim.lsp.buf.rename)
  end

  if caps.codeActionProvider then
    keymap('n', 'gC', vim.lsp.buf.code_action)
  end

  if caps.referencesProvider then
    keymap('n', 'gr', vim.lsp.buf.references)
  end

  if caps.implementationProvider then
    keymap('n', 'gi', vim.lsp.buf.implementation)
  end

  keymap('n', '[g', vim.diagnostic.goto_prev)
  keymap('n', ']g', vim.diagnostic.goto_next)

  if caps.documentHighlightProvider then
    vim.cmd([[
      hi! link LspReferenceRead Visual
      hi! link LspReferenceText Visual
      hi! link LspReferenceWrite Visual
      augroup lsp_document_highlight
        autocmd! * <buffer>
        autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
        autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
      augroup END
    ]])
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
  cmd = { "@TSSERVER_PATH@/bin/typescript-language-server", "--stdio", "--tsserver-path", "@TYPESCRIPT_PATH@/bin/tsserver" },
  on_attach = lsp_on_attach
}

lspconfig.jdtls.setup {
  cmd = {
    "java",
    "-Declipse.application=org.eclipse.jdt.ls.core.id1",
    "-Dosgi.bundles.defaultStartLevel=4",
    "-Declipse.product=org.eclipse.jdt.ls.core.product",
    "-Dlog.protocol=true",
    "-Dlog.level=ALL",
    "-Xms1g",
    "-Xmx2G",
    "--add-modules=ALL-SYSTEM",
    "--add-opens",
    "java.base/java.util=ALL-UNNAMED",
    "--add-opens",
    "java.base/java.lang=ALL-UNNAMED",
    "-jar",
    "/home/aamaruvi/.local/share/jdt/plugins/org.eclipse.equinox.launcher_1.6.400.v20210924-0641.jar",
    "-configuration",
    "/home/aamaruvi/.local/share/jdt/config_linux",
    "-data",
    "/home/aamaruvi/.local/share/jdt/workspace",
  },
  on_attach = lsp_on_attach,
  cmd_env = {
    WORKSPACE = '/home/aamaruvi/school/Documents/eclipse/',
    GRADLE_HOME = '/home/aamaruvi/school/Documents/eclipse/'
  }
}

lspconfig.ccls.setup {
  cmd = { "@CCLS_PATH@/bin/ccls" },
  on_attach = lsp_on_attach
}

lspconfig.pylsp.setup {
  cmd = { "@PYLSP_PATH@/bin/pylsp" },
  on_attach = lsp_on_attach
}
