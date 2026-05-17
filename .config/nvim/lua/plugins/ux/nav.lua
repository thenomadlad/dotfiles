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
      { "<leader>e", "<Cmd>Neotree toggle<CR>", desc = "Toggle neotree explorer" },
    },
    opts = {
      close_if_last_window = true,
      enable_diagnostics = true,
      filesystem = {
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
          hide_gitignored = false,
        },
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = true,
      },
      source_selector = {
        winbar = true,
        sources = {
          { source = "filesystem" },
          { source = "buffers" },
          { source = "git_status" },
          { source = "document_symbols" },
        },
      },
    },
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
