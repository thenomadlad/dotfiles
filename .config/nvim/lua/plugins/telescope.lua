return {
  "nvim-telescope/telescope.nvim", version='0.1.x',
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope-project.nvim",
  },
  opts = function()
    local builtin = require('telescope.builtin')

    -- extensions
    require('telescope').load_extension('project')

    -- finding things
    vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
    vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
    vim.keymap.set({'v', 'n'}, '<leader>fw', builtin.grep_string, { desc = 'Telescope live grep' })

    -- vim things
    vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
    vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })

    -- lsp things
    vim.keymap.set({'v', 'n'}, '<leader>lci', builtin.lsp_incoming_calls, { desc = 'LSP find incoming calls' })
    vim.keymap.set({'v', 'n'}, '<leader>lco', builtin.lsp_outgoing_calls, { desc = 'LSP find outgoing calls' })
    vim.keymap.set({'v', 'n'}, '<leader>li', builtin.lsp_implementations, { desc = 'LSP find implementation(s)' })
    vim.keymap.set({'v', 'n'}, '<leader>ld', builtin.lsp_definitions, { desc = 'LSP find definition(s)' })
    vim.keymap.set({'v', 'n'}, '<leader>ltd', builtin.lsp_type_definitions, { desc = 'LSP find type definition(s)' })

    -- tree sitter things
    vim.keymap.set('n', '<leader>fa', builtin.treesitter, { desc = 'List all using tree sitter' })


  end
}
