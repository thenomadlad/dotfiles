return {
  -- formatting markdown into nicer display
  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = { 'markdown', 'quarto' },
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.icons' },
    opts = function()
      require('render-markdown').setup({
        completions = { lsp = { enabled = true } },
        render_modes = true,
      })

      require('render-markdown').enable()
    end
  },

  -- preview images and diagrams
  {
    "3rd/diagram.nvim",
    dependencies = {
      { "3rd/image.nvim", opts = {
        processor = "magick_cli",
      }}, -- you'd probably want to configure image.nvim manually instead of doing this
    },
    opts = function()
      require("diagram").setup({
        integrations = {
          require("diagram.integrations.markdown"),
          require("diagram.integrations.neorg"),
        },
        renderer_options = {
          mermaid = {
            theme = "forest",
            scale = 3
          },
          plantuml = {
            charset = "utf-8",
          },
          d2 = {
            theme_id = 1,
          },
          gnuplot = {
            theme = "dark",
            size = "800,600",
          },
        },
        events = {
          render_buffer = { "InsertLeave", "BufWinEnter", "TextChanged" },
          clear_buffer = {"BufLeave"},
        },
      })

    end
  }
}
