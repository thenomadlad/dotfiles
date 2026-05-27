return {
  "nvim-telescope/telescope.nvim",
  version = '0.1.x',
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local telescopeConfig = require("telescope.config")

    -- Clone the default Telescope configuration
    local vimgrep_arguments = { unpack(telescopeConfig.values.vimgrep_arguments) }

    -- I want to search in hidden/dot files.
    table.insert(vimgrep_arguments, "--hidden")
    -- I don't want to search in the `.git` directory.
    table.insert(vimgrep_arguments, "--glob")
    table.insert(vimgrep_arguments, "!**/.git/*")

    require("telescope").setup({
      defaults = {
        path_display = {
          shorten = {
            len = 3, exclude = { 1, -1 }
          },
          truncate = true
        },
        dynamic_preview_title = true,
        -- `hidden = true` is not supported in text grep commands.
        vimgrep_arguments = vimgrep_arguments,
      },
      pickers = {
        find_files = {
          -- `hidden = true` will still show the inside of `.git/` as it's not `.gitignore`d.
          find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
        }
      }
    })
  end,
  keys = {
    -- finding things
    { "<leader>ff",  function() require('telescope.builtin').find_files() end,            desc = "Telescope find files" },
    { "<leader>fg",  function() require('telescope.builtin').live_grep() end,             desc = "Telescope live grep" },
    { "<leader>fw",  function() require('telescope.builtin').grep_string() end,           mode = { 'v', 'n' },                      desc = "Telescope grep string" },

    -- vim things
    { "<leader>fb",  function() require('telescope.builtin').buffers() end,               desc = "Telescope buffers" },
    { "<leader>fh",  function() require('telescope.builtin').help_tags() end,             desc = "Telescope help tags" },

    -- lsp things
    { "<leader>lci", function() require('telescope.builtin').lsp_incoming_calls() end,    mode = { 'v', 'n' },                      desc = "LSP find incoming calls" },
    { "<leader>lco", function() require('telescope.builtin').lsp_outgoing_calls() end,    mode = { 'v', 'n' },                      desc = "LSP find outgoing calls" },
    { "<leader>li",  function() require('telescope.builtin').lsp_implementations() end,   mode = { 'v', 'n' },                      desc = "LSP find implementation(s)" },
    { "<leader>ld",  function() require('telescope.builtin').lsp_definitions() end,       mode = { 'v', 'n' },                      desc = "LSP find definition(s)" },
    { "<leader>ltd", function() require('telescope.builtin').lsp_type_definitions() end,  mode = { 'v', 'n' },                      desc = "LSP find type definition(s)" },
    { "<leader>lds", function() require('telescope.builtin').lsp_document_symbols() end,  desc = "LSP document symbols (this file)" },
    { "<leader>lws", function() require('telescope.builtin').lsp_workspace_symbols() end, desc = "LSP workspace symbols" },

    -- treesitter things
    { "<leader>fa",  function() require('telescope.builtin').treesitter() end,            desc = "List all using treesitter" },
  },
}
