return {
  "otavioschwanck/arrow.nvim",
  dependencies = {
    { "nvim-tree/nvim-web-devicons" },
    -- or if using `mini.icons`
    -- { "echasnovski/mini.icons" },
  },
  opts = {
    show_icons = true,
    leader_key = '<leader>pp', -- Recommended to be a single key
    buffer_leader_key = '<leader>pb', -- Recommended to be a single key
  }
}
