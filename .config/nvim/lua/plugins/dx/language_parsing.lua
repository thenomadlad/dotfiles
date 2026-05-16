return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = {
      ensure_installed = { "c", "lua", "vim", "rust", "vimdoc", "query", "markdown", "markdown_inline", "python", "java" },
      auto_install = true,
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
      indent = {
        enable = true
      }
    },
  },

  {
    'williamboman/mason.nvim',
    opts = {},
  },

  {
    'neovim/nvim-lspconfig',
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',
      'nvimtools/none-ls.nvim',
      'nvim-java/nvim-java',
      {
        'jay-babu/mason-null-ls.nvim',
        event = { 'BufReadPre', 'BufNewFile' },
      },
      {
        "mrcjkb/rustaceanvim",
        version = '^5',
        ft = "rust",
        dependencies = { "mfussenegger/nvim-dap" },
      },
    },
    config = function()
      require('mason-lspconfig').setup({
        ensure_installed = {
          'lua_ls', 'rust_analyzer', 'pylsp', 'ts_ls',
          'astro', 'tailwindcss', 'just', 'jdtls',
        },
        automatic_enable = {
          exclude = { "rust_analyzer" }
        }
      })
      require('mason-null-ls').setup({ handlers = {} })

      vim.lsp.enable('astro')
      vim.lsp.enable('tailwindcss')
      vim.lsp.enable('just')

      vim.lsp.config("lua_ls", {
        on_init = function(client)
          local real_nvim_config = vim.fn.resolve(vim.fn.stdpath("config"))
          local real_root = vim.fn.resolve(client.workspace_folders[1].name)

          if real_root and real_nvim_config and vim.startswith(real_root, real_nvim_config) then
            client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua or {}, {
              runtime = { version = "LuaJIT" },
              workspace = {
                checkThirdParty = false,
                library = vim.api.nvim_get_runtime_file("", true),
              },
              diagnostics = { globals = { "vim" } },
            })
            client:notify("workspace/didChangeConfiguration", { settings = client.config.settings })
          end
        end,
      })

      vim.lsp.config('pylsp', {
        settings = {
          pylsp = {
            plugins = { rope_autoimport = { enabled = true } }
          }
        }
      })

      require('java').setup()
      vim.lsp.enable('jdtls')

      vim.keymap.set("n", "<leader>la", vim.lsp.buf.code_action, { desc = "LSP code action" })
      vim.keymap.set("v", "<leader>la", vim.lsp.buf.code_action, { desc = "LSP code action" })
      vim.keymap.set("n", "<leader>lr", vim.lsp.buf.rename, { desc = "LSP rename symbol" })
      vim.keymap.set("n", "<leader>lgd", vim.lsp.buf.definition, { desc = "LSP go to definition" })
      vim.keymap.set("n", "<leader>ldn", vim.diagnostic.jump, { desc = "LSP go to next issue" })
      vim.keymap.set("n", "<leader>ldp", function() vim.diagnostic.jump({ count = -1 }) end, { desc = "LSP go to previous issue" })

      vim.lsp.inlay_hint.enable()
    end
  },

  {
    'mfussenegger/nvim-dap',
    dependencies = {
      'nvim-neotest/nvim-nio',
      'igorlfs/nvim-dap-view',
      'jay-babu/mason-nvim-dap.nvim',
      'williamboman/mason.nvim',
    },
    config = function()
      require('mason-nvim-dap').setup()
    end,
    keys = {
      { "<leader>dc",  function() require('dap').continue() end, desc = "Continue or start a debug session" },
      { "<leader>db",  function() require('dap').toggle_breakpoint() end, desc = "Toggle breakpoint on line" },
      { "<leader>drtc", function() require('dap').run_to_cursor() end, desc = "Run to cursor" },
      { "<leader>dso", function() require('dap').step_over() end, desc = "Step over" },
      { "<leader>dsi", function() require('dap').step_into() end, desc = "Step into" },
      { "<leader>dt",  function() require('dap').terminate() end, desc = "Terminate debug session" },
      { "<leader>dv",  function() vim.cmd [[DapViewToggle]] end, desc = "Dap view toggle" },
      { "<leader>dw",  function() vim.cmd [[DapViewWatch]] end, mode = { "n", "v" }, desc = "Watch variable under cursor" },
    },
  },
}
