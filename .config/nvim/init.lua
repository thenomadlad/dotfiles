require("settings")
require("lazy_plugins")
require("theme")

vim.cmd.colorscheme "catppuccin"

-- auto twilight
vim.api.nvim_create_autocmd("BufRead", {
    callback = function()
        require("twilight").enable()
    end,
})
