return {
  -- sensible defaults to UX
  {
    'stevearc/dressing.nvim',
    event = "VeryLazy"
  },

  -- lua/plugins/rose-pine.lua
  {
    "rose-pine/neovim",
    name = "rose-pine",
    config = function()
      vim.cmd("colorscheme rose-pine")
    end
  },

  -- focus and highlighting
  {
    "thenomadlad/twilight.nvim",
    branch = "fix/treesitter-parser-crash",
    opts = {
      context = 25
    }
  },

  -- cmdline and notifiations
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
      -- add any options here
    },
    dependencies = {
      -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
      "MunifTanjim/nui.nvim",
      -- OPTIONAL:
      --   `nvim-notify` is only needed, if you want to use the notification view.
      --   If not available, we use `mini` as the fallback
      {
        "rcarriga/nvim-notify",
        opts = {
          top_down = false,
          render = "compact",
          timeout = 1000
        },
      },
    }
  },

  -- diagnostic
  {
    'rachartier/tiny-inline-diagnostic.nvim',
    event = 'LspAttach',
    config = function()
      -- disable default
      vim.diagnostic.config({
        virtual_text = false,
      })

      require('tiny-inline-diagnostic').setup({
        options = {
          show_source = true,
          multilines = true
        }
      })
    end
  }
}
