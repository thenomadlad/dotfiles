return {
  {"okuuva/auto-save.nvim", opts = { debounce_delay = 500 }},
  {
    'windwp/nvim-autopairs',
    event = "InsertEnter",
    config = true
  },

  -- managing codeblocks
  {
    "numToStr/Comment.nvim",
    opts = {
      ---LHS of toggle mappings in NORMAL mode
      toggler = {
        ---Line-comment toggle keymap
        line = '<leader>/',
      },
      ---LHS of operator-pending mappings in NORMAL and VISUAL mode
      opleader = {
        ---Line-comment keymap
        line = '<leader>/',
      },
    },
    lazy = false,
  },

  -- showing indents
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = function()
      require("ibl").setup()
    end
  },

  -- showing location in module
  {
    "nvim-treesitter/nvim-treesitter-context",
    opts = {
      enable = true,
      multiwindow = false,
      max_lines = 0,
      min_window_height = 0,
      line_numbers = true,
      multiline_threshold = 20,
      trim_scope = 'outer',
      mode = 'cursor',
      separator = '~',
      zindex = 20,
      on_attach = nil,
    }
  }
}
