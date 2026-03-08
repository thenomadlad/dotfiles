return {
  'williamboman/mason.nvim',
  dependencies = {
    'williamboman/mason-lspconfig.nvim',
    'neovim/nvim-lspconfig',
    'mfussenegger/nvim-dap',
    'nvim-neotest/nvim-nio',
    'igorlfs/nvim-dap-view',
    'jay-babu/mason-nvim-dap.nvim',
    'nvimtools/none-ls.nvim',
    {
      'jay-babu/mason-null-ls.nvim',
      event = { 'BufReadPre', 'BufNewFile' },
    }
  },
  opts = function()
    require('mason').setup()
    require('mason-lspconfig').setup({
      ensure_installed = {
        'lua_ls',
        'rust_analyzer',
        'pylsp',
        'ts_ls',
      },
      automatic_enable = {
        exclude = {
          -- rustacean-nvim handles config
          "rust_analyzer",
        }
      }
    })
    require('mason-nvim-dap').setup()
    require('mason-null-ls').setup({
      handlers = {}
    })

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
            diagnostics = {
              globals = { "vim" },
            },
          })
          client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
        end
      end,
    })

    vim.lsp.config('pylsp', {
      settings = {
        pylsp = {
          plugins = {
            rope_autoimport = {
              enabled = true
            }
          }
        }
      }
    })

    -- lsp action
    vim.keymap.set("n", "<leader>la", vim.lsp.buf.code_action, { desc="LSP code action" })
    vim.keymap.set("v", "<leader>la", vim.lsp.buf.code_action, { desc="LSP code action" })
    vim.keymap.set("n", "<leader>lr", vim.lsp.buf.rename, { desc="LSP rename symbol" })
    vim.keymap.set("n", "<leader>lgd", vim.lsp.buf.definition, { desc="LSP go to definition" })
    vim.keymap.set("n", "<leader>ldn", vim.diagnostic.goto_next, { desc="LSP go to next issue" })
    vim.keymap.set("n", "<leader>ldp", vim.diagnostic.goto_prev, { desc="LSP go to previous issue" })

    -- lsp inlining
    vim.lsp.inlay_hint.enable()

    -- dap stuff
    local dap = require("dap")

    if dap then
      vim.keymap.set("n", "<leader>dc", dap.continue, { desc="Continue or start a debug session" })
      vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc="Toggle breakpoint on line" })
      vim.keymap.set("n", "<leader>drtc", dap.run_to_cursor, { desc="Run to cursor" })
      vim.keymap.set("n", "<leader>dso", dap.step_over, { desc="Step over" })
      vim.keymap.set("n", "<leader>dsi", dap.step_into, { desc="Step into" })
      vim.keymap.set("n", "<leader>dt", dap.terminate, { desc="Terminate debug session" })
    end

    vim.keymap.set("n", "<leader>dv", function() vim.cmd [[DapViewToggle]] end, { desc = "Dap view toggle" })
    vim.keymap.set("n", "<leader>dw", function() vim.cmd [[DapViewWatch]] end, { desc = "Watch variable under cursor" })
    vim.keymap.set("v", "<leader>dw", function() vim.cmd [[DapViewWatch]] end, { desc = "Watch variable in selection" })
  end
}
