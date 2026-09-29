return {
  "lewis6991/gitsigns.nvim",
  lazy = false,
  keys = {
    { "]h", "<cmd>Gitsigns nav_hunk next<CR>", desc = "Next hunk" },
    { "[h", "<cmd>Gitsigns nav_hunk prev<CR>", desc = "Previous hunk" },
    { "<leader>gp", "<cmd>Gitsigns preview_hunk<CR>", desc = "Preview hunk" },
    { "<leader>gs", "<cmd>Gitsigns stage_hunk<CR>", desc = "Stage hunk" },
    { "<leader>gr", "<cmd>Gitsigns reset_hunk<CR>", desc = "Reset hunk" },
  },
  opts = {},
}
