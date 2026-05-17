return {
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
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
      trim_scope = "outer",
      mode = "cursor",
      separator = nil,
      zindex = 20,
      on_attach = nil,
    },
  },

  {
    "saecki/live-rename.nvim",
    keys = {
      {
        "<leader>lr",
        function() require("live-rename").rename() end,
        desc = "Rename symbol (live)",
      },
    },
  },

  {
    "aaronik/treewalker.nvim",
    keys = {
      {
        "<leader>bmk",
        ":Treewalker SwapUp",
        desc = "Move block up",
      },
      {
        "<leader>bmj",
        ":Treewalker SwapDown",
        desc = "Move block down",
      },
      {
        "<leader>bmh",
        ":Treewalker SwapLeft",
        desc = "Move block left",
      },
      {
        "<leader>bml",
        ":Treewalker SwapRight",
        desc = "Move block right",
      },
    },
  },

  { "hat0uma/csvview.nvim", ft = "csv" },
}
