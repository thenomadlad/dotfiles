return {
  'MeanderingProgrammer/render-markdown.nvim',
  ft = { 'markdown', 'quarto' },
  dependencies = { 'nvim-treesitter/nvim-treesitter',
  "nvim-tree/nvim-web-devicons" },
  opts = function()
    require('render-markdown').setup({
      completions = { lsp = { enabled = true } },
      render_modes = true,
    })

    require('render-markdown').enable()
  end
}
