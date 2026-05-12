return {
  "yousefhadder/markdown-plus.nvim",
  ft = "markdown",
  opts = function()
    require("markdown-plus").setup({
      features = {
        table = true
      },
      table = {
        enabled = true,
        auto_format = true,
        default_alignment = "left",
        confirm_destructive = true,
        keymaps = {
          enabled = true,
          prefix = "<leader>mt",
          insert_mode_navigation = true,
        },
      },
    })
  end
}
