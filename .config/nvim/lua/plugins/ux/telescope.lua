return {
  "nvim-telescope/telescope.nvim", version = '0.1.x',
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    -- finding things
    { "<leader>ff", function() require('telescope.builtin').find_files() end, desc = "Telescope find files" },
    { "<leader>fg", function() require('telescope.builtin').live_grep() end, desc = "Telescope live grep" },
    { "<leader>fw", function() require('telescope.builtin').grep_string() end, mode = { 'v', 'n' }, desc = "Telescope grep string" },

    -- vim things
    { "<leader>fb", function() require('telescope.builtin').buffers() end, desc = "Telescope buffers" },
    { "<leader>fh", function() require('telescope.builtin').help_tags() end, desc = "Telescope help tags" },

    -- lsp things
    { "<leader>lci", function() require('telescope.builtin').lsp_incoming_calls() end, mode = { 'v', 'n' }, desc = "LSP find incoming calls" },
    { "<leader>lco", function() require('telescope.builtin').lsp_outgoing_calls() end, mode = { 'v', 'n' }, desc = "LSP find outgoing calls" },
    { "<leader>li",  function() require('telescope.builtin').lsp_implementations() end, mode = { 'v', 'n' }, desc = "LSP find implementation(s)" },
    { "<leader>ld",  function() require('telescope.builtin').lsp_definitions() end, mode = { 'v', 'n' }, desc = "LSP find definition(s)" },
    { "<leader>ltd", function() require('telescope.builtin').lsp_type_definitions() end, mode = { 'v', 'n' }, desc = "LSP find type definition(s)" },

    -- treesitter things
    { "<leader>fa", function() require('telescope.builtin').treesitter() end, desc = "List all using treesitter" },
  },
}
