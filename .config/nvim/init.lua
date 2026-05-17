require "settings"
require "lazy_plugins"

-- auto twilight
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    if vim.bo[args.buf].buftype ~= "" then return end

    local ok, parser = pcall(vim.treesitter.get_parser, args.buf)
    if ok and parser then require("twilight").enable() end
  end,
})
