vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.updatetime = 300
vim.opt.clipboard = "unnamedplus"
vim.opt.termguicolors = true

vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.softtabstop = 2
vim.opt.fillchars = { eob = " " }

vim.keymap.set("i", "jk", "<ESC>", { silent = true })
vim.keymap.set("n", "<leader>c", ":bd<CR>", { silent = true })

-- numbering
vim.opt.cursorline = true
vim.opt.number = true
vim.opt.relativenumber = true
