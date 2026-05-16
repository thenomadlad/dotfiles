return {
  { "okuuva/auto-save.nvim", opts = { debounce_delay = 500 } },

  {
    'windwp/nvim-autopairs',
    event = "InsertEnter",
    opts = {},
  },

  {
    "numToStr/Comment.nvim",
    opts = {
      toggler = { line = '<leader>/' },
      opleader = { line = '<leader>/' },
    },
  },

  {
    "lukas-reineke/indent-blankline.nvim",
    event = "BufReadPost",
    main = "ibl",
    opts = {},
  },

  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "BufReadPost",
    opts = {
      enable = true,
      multiwindow = false,
      max_lines = 0,
      min_window_height = 0,
      line_numbers = true,
      multiline_threshold = 20,
      trim_scope = 'outer',
      mode = 'cursor',
      separator = nil,
      zindex = 20,
      on_attach = nil,
    }
  },
}
