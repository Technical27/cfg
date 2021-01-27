pkgs: {
  "coc.preferences.formatOnSaveFiletypes" = [
    "javascript"
    "vue"
    "html"
    "css"
    "json"
    "rust"
  ];
  "prettier.singleQuote" = true;
  "signature.maxWindowHeight" = 16;
  "suggest.noselect" = false;
  "eslint.autoFixOnSave" = true;
  "eslint.filetypes" = [
    "javascript"
    "javascriptreact"
    "typescript"
    "typescriptreact"
    "vue"
  ];
  "tabnine.limit" = 5;
  "tabnine.priority" = 70;
  "suggest.languageSourcePriority" = 80;
  languageserver.nix = {
    command = "${pkgs.rnix-lsp}/bin/rnix-lsp";
    filetypes = [ "nix" ];
  };
}
