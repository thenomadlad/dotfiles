return {
  -- treesitter and parsing, highlighting etc
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = {
      -- A list of parser names, or "all" (the listed parsers MUST always be installed)
      ensure_installed = { "c", "lua", "vim", "rust", "vimdoc", "query", "markdown", "markdown_inline", "python", "java" },

      -- Automatically install missing parsers when entering buffer
      -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
      auto_install = true,

      -- List of parsers to ignore installing (or "all")
      -- ignore_install = { "javascript" },

      ---- If you need to change the installation directory of the parsers (see -> Advanced Setup)
      -- parser_install_dir = "/some/path/to/store/parsers", -- Remember to run vim.opt.runtimepath:append("/some/path/to/store/parsers")!

      highlight = {
        enable = true,

        -- NOTE: these are the names of the parsers and not the filetype. (for example if you want to
        -- disable highlighting for the `tex` filetype, you need to include `latex` in this list as this is
        -- the name of the parser)
        -- list of language that will be disabled
        -- disable = { "c", "rust" },
        -- Or use a function for more flexibility, e.g. to disable slow treesitter highlight for large files
        -- disable = function(lang, buf)
          --     local max_filesize = 100 * 1024 -- 100 KB
          --     local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
          --     if ok and stats and stats.size > max_filesize then
          -- 	  return true
          --     end
          -- end,

          -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
          -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
          -- Using this option may slow down your editor, and you may see some duplicate highlights.
          -- Instead of true it can also be a list of languages
          additional_vim_regex_highlighting = false,
        },
        indent = {
          enable = true
        }
      }
    },

    -- mason for the rest of the stuff below
    {
      'williamboman/mason.nvim',
      opts = function()
        require("mason").setup()
      end
    },

    -- lsp config
    -- ok i dont know why we ended up with this pattern but the dependencies are required for the setup function of the main nvim-lspconfig module
    {
        'neovim/nvim-lspconfig',
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
          -- Automatically sets up LSP, so lsp.lua doesn't include rust.
          -- Makes debugging work seamlessly.
          "mrcjkb/rustaceanvim",
          version = '^5', -- Recommended by module.
          ft = "rust",
          dependencies = {
            "mfussenegger/nvim-dap",
          },
        },
      },
      config = function()
        require('mason-lspconfig').setup({
          ensure_installed = {
            'lua_ls',
            'rust_analyzer',
            'pylsp',
            'ts_ls',
            'astro',
            'tailwindcss',
            'just',
            'jdtls'
          },
          automatic_enable = {
            exclude = {
              -- rustacean-nvim handles config
              "rust_analyzer",
            }
          }
        })
        require('mason-null-ls').setup({
          handlers = {}
        })

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
                diagnostics = {
                  globals = { "vim" },
                },
              })
              client:notify("workspace/didChangeConfiguration", { settings = client.config.settings })
            end
          end,
        })

        -- python
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

        -- java
        require('java').setup()
        vim.lsp.enable('jdtls')

        -- lsp action
        local function jump_prev()
          vim.diagnostic.jump({count = -1})
        end;

        vim.keymap.set("n", "<leader>la", vim.lsp.buf.code_action, { desc="LSP code action" })
        vim.keymap.set("v", "<leader>la", vim.lsp.buf.code_action, { desc="LSP code action" })
        vim.keymap.set("n", "<leader>lr", vim.lsp.buf.rename, { desc="LSP rename symbol" })
        vim.keymap.set("n", "<leader>lgd", vim.lsp.buf.definition, { desc="LSP go to definition" })
        vim.keymap.set("n", "<leader>ldn", vim.diagnostic.jump, { desc="LSP go to next issue" })
        vim.keymap.set("n", "<leader>ldp", jump_prev, { desc="LSP go to previous issue" })

        -- lsp inlining
        vim.lsp.inlay_hint.enable()
      end
    },

    -- dap stuff
    -- similar to above, we ended up adding additional features as "dependencies" and updated the setup function of the main module to load everything
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      'nvim-neotest/nvim-nio',
      'igorlfs/nvim-dap-view',
      'jay-babu/mason-nvim-dap.nvim',
      'williamboman/mason.nvim',
    },
    config = function()
      local dap = require("dap")

      if dap then
        require('mason-nvim-dap').setup()

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
}
