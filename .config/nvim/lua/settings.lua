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
vim.api.nvim_create_user_command("AgentYankRange", function(args)
  require("agent_context").yank_range(args.line1, args.line2)
end, { range = true })
vim.api.nvim_create_user_command("AgentYankGithub", function(args)
  require("agent_context").yank_github_range(args.line1, args.line2)
end, { range = true })

vim.keymap.set("n", "<leader>ya", function() require("agent_context").yank_line() end, {
  desc = "Yank agent context (line)",
})
vim.keymap.set("v", "<leader>ya", ":'<,'>AgentYankRange<CR>", {
  silent = true,
  desc = "Yank agent context (range)",
})
vim.keymap.set("n", "<leader>yg", function() require("agent_context").yank_github_line() end, {
  desc = "Yank GitHub URL (line)",
})
vim.keymap.set("v", "<leader>yg", ":'<,'>AgentYankGithub<CR>", {
  silent = true,
  desc = "Yank GitHub URL (range)",
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
