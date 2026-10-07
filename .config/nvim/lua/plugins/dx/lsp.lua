return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      { "williamboman/mason-lspconfig.nvim", event = { "BufReadPre", "BufNewFile" } },
      "mfussenegger/nvim-jdtls",
      "folke/lazydev.nvim",
    },
    config = function()
      -- Kotlin sources + Kotlin DSL (build.gradle.kts, *.kts) → kotlin ft for kotlin_language_server
      vim.filetype.add { extension = { kt = "kotlin", kts = "kotlin" } }

      require("mason-lspconfig").setup {
        ensure_installed = {
          "lua_ls",
          "rust_analyzer",
          "pylsp",
          "ts_ls",
          "astro",
          "tailwindcss",
          "eslint",
          "just",
          "jdtls",
          "lemminx",
          -- Gradle Kotlin DSL (.gradle.kts, *.kts scripts) + Kotlin sources
          "kotlin_language_server",
          -- Groovy Gradle DSL (build.gradle, settings.gradle)
          "gradle_ls",
        },
        -- automatic_enable = {
        --   exclude = { "rust_analyzer" },
        -- },
      }

      -- Merge after mason-lspconfig baselines (cmd from Mason, etc.); see nvim-lspconfig lsp/*.lua
      vim.lsp.config("kotlin_language_server", {
        init_options = {
          storagePath = vim.fn.stdpath "cache" .. "/kotlin-language-server",
        },
      })
      vim.lsp.config("gradle_ls", {
        init_options = {
          settings = {
            gradleWrapperEnabled = true,
          },
        },
      })

      vim.lsp.enable "astro"
      vim.lsp.enable "tailwindcss"
      vim.lsp.enable "eslint"
      vim.lsp.enable "just"
      vim.lsp.enable "rust_analyzer"

      -- Mason installs pylsp into its own isolated venv, so by default jedi
      -- (completion/type inference) only sees packages installed there, not
      -- whatever the project actually depends on. Ask the project's own
      -- package manager where its venv/interpreter lives, based on whichever
      -- lockfile is present, and point jedi at that instead.
      local function detect_venv_python(root_dir)
        local function run(cmd)
          local result = vim.system(cmd, { cwd = root_dir, text = true }):wait()
          if result.code == 0 then
            return vim.trim(result.stdout or "")
          end
        end

        if vim.fn.filereadable(root_dir .. "/poetry.lock") == 1 then
          local path = run { "poetry", "env", "info", "--executable" }
          if path and vim.fn.executable(path) == 1 then
            return path
          end
        elseif vim.fn.filereadable(root_dir .. "/uv.lock") == 1 then
          local path = run { "uv", "run", "--", "python", "-c", "import sys; print(sys.executable)" }
          if path and vim.fn.executable(path) == 1 then
            return path
          end
          -- fall back to uv's default in-project venv location
          local fallback = root_dir .. "/.venv/bin/python"
          if vim.fn.executable(fallback) == 1 then
            return fallback
          end
        end
      end

      vim.lsp.config("pylsp", {
        before_init = function(_, config)
          -- Mutate settings in place: `client.settings` is captured by
          -- reference before before_init runs, so reassigning
          -- `config.settings` here (e.g. via tbl_deep_extend) would silently
          -- be dropped -- the client would keep notifying the server with
          -- the stale table.
          local venv_python = detect_venv_python(config.root_dir)
          if venv_python then
            config.settings.pylsp.plugins.jedi.environment = venv_python
          end
        end,
        settings = {
          pylsp = {
            plugins = {
              rope_autoimport = { enabled = true },
              jedi = vim.empty_dict(),
            },
          },
        },
      })

      vim.keymap.set("n", "<leader>la", vim.lsp.buf.code_action, { desc = "LSP code action" })
      vim.keymap.set("v", "<leader>la", vim.lsp.buf.code_action, { desc = "LSP code action" })
      vim.keymap.set("n", "<leader>lr", vim.lsp.buf.rename, { desc = "LSP rename symbol" })
      vim.keymap.set("n", "<leader>lgd", vim.lsp.buf.definition, { desc = "LSP go to definition" })

      vim.lsp.inlay_hint.enable()
    end,
  },

  {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    keys = {
      {
        "<leader>lf",
        function() require("conform").format { async = true, lsp_fallback = true } end,
        mode = { "n", "v" },
        desc = "Format buffer or selection",
      },
    },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "ruff_format" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        astro = { "prettier" },
        css = { "prettier" },
        html = { "prettier" },
        json = { "prettier" },
        markdown = { "prettier" },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
      },
    },
  },

  -- neovim development
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      opts.sources = opts.sources or {}
      opts.sources.default = vim.list_extend(opts.sources.default or { "lsp", "path", "snippets", "buffer" }, { "lazydev" })
      opts.sources.providers = vim.tbl_deep_extend("force", opts.sources.providers or {}, {
        lazydev = {
          name = "LazyDev",
          module = "lazydev.integrations.blink",
          score_offset = 100,
        },
      })
    end,
  },

  -- -- rust
  -- {
  --   "mrcjkb/rustaceanvim",
  --   dependencies = { "mfussenegger/nvim-dap" },
  --   lazy = false, -- mrcjkb feels confident he has lazy loading correctly set setup
  --   init = function()
  --     vim.g.rustaceanvim = {
  --       server = {
  --         settings = {
  --           ["rust-analyzer"] = {
  --             check = { command = "clippy" },
  --           },
  --         },
  --       },
  --     }
  --   end,
  -- },
}
