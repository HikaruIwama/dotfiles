return {
  "nvim-telescope/telescope.nvim",
  version = "*",
  dependencies = { "nvim-lua/plenary.nvim" },
  cmd = "Telescope",
  keys = {
    { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find files" },
    { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Search text" },
    { "<leader>fc", "<cmd>Telescope current_buffer_fuzzy_find<CR>", desc = "Search current buffer" },
  },
  opts = {
    defaults = {
      sorting_strategy = "ascending",
      layout_config = { prompt_position = "top" },
    },
  },
}
