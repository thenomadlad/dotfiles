return {
  'MeanderingProgrammer/render-markdown.nvim',
  ft = { 'markdown', 'quarto' },
  dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.nvim' },
  opts = function()
    require('render-markdown').setup({
        completions = { lsp = { enabled = true } },
        render_modes = true,
    })

    require('render-markdown').enable()
  end
}
