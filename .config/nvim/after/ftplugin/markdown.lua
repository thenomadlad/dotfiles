vim.opt_local.wrap = true
vim.opt_local.linebreak = true
vim.opt_local.spell = true
vim.opt_local.conceallevel = 2

if vim.fn.has "mac" == 1 then
  -- Hand the file to Byword; saves first so it opens what's in the buffer
  vim.api.nvim_buf_create_user_command(0, "Byword", function()
    vim.cmd.update()
    vim.system { "open", "-a", "Byword", vim.api.nvim_buf_get_name(0) }
  end, { desc = "Open this file in Byword" })
end
