vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.opt.number = true
vim.opt.signcolumn = "yes"

vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.undofile = true

vim.diagnostic.config({ virtual_text = true })

vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "CursorHoldI" }, {
  group = vim.api.nvim_create_augroup("reload_changed_files", { clear = true }),
  callback = function()
    if vim.fn.getcmdwintype() == "" then
      vim.cmd.checktime()
    end
  end,
})

require("config.lazy")
