return {
  {
    "numToStr/Navigator.nvim",
    keys = {
      { "<C-h>", "<CMD>NavigatorLeft<CR>" },
      { "<C-j>", "<CMD>NavigatorDown<CR>" },
      { "<C-k>", "<CMD>NavigatorUp<CR>" },
      { "<C-l>", "<CMD>NavigatorRight<CR>" },
    },
  },

  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
      { "3rd/image.nvim", cond = function() return #vim.api.nvim_list_uis() > 0 end },
    },
    keys = {
      { "<leader>e", "<Cmd>Neotree toggle last position=left<CR>", desc = "Toggle neotree explorer" },
    },
    ---@module 'neo-tree'
    ---@type neotree.Config
    opts = {
      close_if_last_window = true,
      enable_diagnostics = true,
      -- document_symbols must be listed here; source_selector alone does not load the source
      -- (defaults.lua keeps document_symbols commented out of `sources`).
      sources = {
        "filesystem",
        "buffers",
        "git_status",
        "document_symbols",
      },
      document_symbols = {
        client_filters = "first",
      },
      filesystem = {
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
          hide_gitignored = false,
        },
        follow_current_file = { enabled = true },
        group_empty_dirs = true,
        use_libuv_file_watcher = true,
      },
      source_selector = {
        truncation_character = "…",
        tabs_layout = "equal",
        content_layout = "center",
        separator = { left = "", right = "" },
        winbar = true,
        sources = {
          { source = "filesystem" },
          { source = "buffers" },
          { source = "git_status" },
          { source = "document_symbols" },
        },
      },
      window = {
        -- default is float - lets us see a floating window on opening a directory
        -- and overriding netrw default behavior. Use position=left when
        -- opening Neotree
        position = "float"
      }
    },
  },
  {
    "antosha417/nvim-lsp-file-operations",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-neo-tree/neo-tree.nvim", -- makes sure that this loads after Neo-tree.
    },
    config = function()
      require("lsp-file-operations").setup()
    end,
  },

  {
    "error311/wayfinder.nvim",
    opts = {},
    keys = {
      {
        "<leader>bn",
        "<Plug>(WayfinderOpen)",
        desc = "Explore code usages etc",
      },
    },
  },

  {
    "folke/trouble.nvim",
    opts = {}, -- for default options, refer to the configuration section for custom setup.
    cmd = "Trouble",
    keys = {
      {
        "<leader>bx",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Diagnostics (Trouble)",
      },
      {
        "<leader>bX",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer Diagnostics (Trouble)",
      },
      {
        "<leader>bs",
        "<cmd>Trouble symbols toggle focus=false<cr>",
        desc = "Symbols (Trouble)",
      },
      {
        "<leader>bl",
        "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
        desc = "LSP Definitions / references / ... (Trouble)",
      },
      {
        "<leader>bL",
        "<cmd>Trouble loclist toggle<cr>",
        desc = "Location List (Trouble)",
      },
      {
        "<leader>bQ",
        "<cmd>Trouble qflist toggle<cr>",
        desc = "Quickfix List (Trouble)",
      },
    },
  },
}
