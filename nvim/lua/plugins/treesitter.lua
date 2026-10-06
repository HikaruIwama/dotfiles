return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").install({
      "bash",
      "css",
      "go",
      "html",
      "javascript",
      "json",
      "python",
      "rust",
      "sql",
      "toml",
      "tsx",
      "typescript",
      "yaml",
    })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = {
        "bash",
        "css",
        "go",
        "html",
        "javascript",
        "javascriptreact",
        "json",
        "lua",
        "markdown",
        "python",
        "rust",
        "sh",
        "sql",
        "toml",
        "typescript",
        "typescriptreact",
        "yaml",
      },
      callback = function(args)
        vim.treesitter.start(args.buf)
      end,
    })
  end,
}
