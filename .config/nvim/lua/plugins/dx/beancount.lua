-- Syntax highlighting comes from Treesitter (see language_parsing.lua); this
-- just teaches Neovim to recognize the filetype, which vim-beancount used to.
vim.filetype.add { extension = { bean = "beancount", beancount = "beancount" } }

return {}
