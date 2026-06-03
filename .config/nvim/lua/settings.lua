vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.updatetime = 300
vim.opt.clipboard = "unnamedplus"
vim.opt.termguicolors = true

-- spacing
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.softtabstop = 2
vim.opt.fillchars = { eob = " " }

-- keymaps
vim.keymap.set("i", "jk", "<ESC>", { silent = true })
vim.keymap.set("n", "<leader>c", ":bd<CR>", { silent = true })
vim.keymap.set("n", "<leader>?", function() require("key_guide").start("n") end, { desc = "Key guide" })
vim.keymap.set("n", "<leader>dn", vim.diagnostic.jump, { desc = "Diagnostics go to next issue" })
vim.keymap.set(
  "n",
  "<leader>dp",
  function() vim.diagnostic.jump { count = -1 } end,
  { desc = "Diagnostics go to previous issue" }
)
vim.keymap.set("n", "<leader>ay", function() require("agent_context").yank_line() end, {
  desc = "Yank agent context (line)",
})
vim.keymap.set("v", "<leader>ay", function() require("agent_context").yank_range() end, {
  desc = "Yank agent context (range)",
})

-- numbering
vim.opt.cursorline = true
vim.opt.number = true
vim.opt.relativenumber = true

-- wrap and fold
vim.opt.wrap = false
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldenable = false
