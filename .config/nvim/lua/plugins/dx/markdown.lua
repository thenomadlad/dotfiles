return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = { 'markdown', 'quarto' },
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.icons' },
    opts = {
      completions = { lsp = { enabled = true } },
      render_modes = true,
    },
  },

  {
    "3rd/diagram.nvim",
    cond = function() return #vim.api.nvim_list_uis() > 0 end,
    dependencies = {
      { "3rd/image.nvim", opts = { processor = "magick_cli" }},
    },
    config = function()
      require("diagram").setup({
        integrations = {
          require("diagram.integrations.markdown"),
          require("diagram.integrations.neorg"),
        },
        renderer_options = {
          mermaid = { theme = "forest", scale = 3 },
          plantuml = { charset = "utf-8" },
          d2 = { theme_id = 1 },
          gnuplot = { theme = "dark", size = "800,600" },
        },
        events = {
          render_buffer = { "InsertLeave", "BufWinEnter", "TextChanged" },
          clear_buffer = { "BufLeave" },
        },
      })
    end
  },
}
