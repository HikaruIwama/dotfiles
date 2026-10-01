return {
  "nvim-tree/nvim-tree.lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  lazy = false,
  keys = {
    { "<leader>e", "<cmd>NvimTreeToggle<CR>", desc = "Toggle file tree" },
  },
  opts = {
    git = {
      timeout = 2000,
    },
    renderer = {
      highlight_git = "name",
      icons = {
        git_placement = "right_align",
        glyphs = {
          git = {
            unstaged = "M",
            staged = "A",
            unmerged = "C",
            renamed = "R",
            untracked = "U",
            deleted = "D",
          },
        },
      },
    },
  },
}
