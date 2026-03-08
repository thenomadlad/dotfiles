return {
  'rachartier/tiny-inline-diagnostic.nvim',
  event = 'VeryLazy', -- Or `LspAttach`
  priority = 1000, -- needs to be loaded in first
  config = function()
    -- disable default
    vim.diagnostic.config({virtual_text = false})

    require('tiny-inline-diagnostic').setup({
      options = {
        show_source = true,
        multilines = true
      }
    })
  end
}
