return {
  "neovim/nvim-lspconfig",
  lazy = false,
  config = function()
    vim.lsp.enable("lua_ls")
    vim.lsp.enable("vtsls")
    vim.lsp.enable("gopls")
  end,
}
