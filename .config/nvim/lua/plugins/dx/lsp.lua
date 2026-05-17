return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "mfussenegger/nvim-jdtls",
      "mrcjkb/rustaceanvim",
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
        automatic_enable = {
          exclude = { "rust_analyzer" },
        },
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

      vim.lsp.config("pylsp", {
        settings = {
          pylsp = {
            plugins = { rope_autoimport = { enabled = true } },
          },
        },
      })

      vim.keymap.set("n", "<leader>la", vim.lsp.buf.code_action, { desc = "LSP code action" })
      vim.keymap.set("v", "<leader>la", vim.lsp.buf.code_action, { desc = "LSP code action" })
      vim.keymap.set("n", "<leader>lr", vim.lsp.buf.rename, { desc = "LSP rename symbol" })
      vim.keymap.set("n", "<leader>lgd", vim.lsp.buf.definition, { desc = "LSP go to definition" })
      vim.keymap.set("n", "<leader>ldn", vim.diagnostic.jump, { desc = "LSP go to next issue" })
      vim.keymap.set(
        "n",
        "<leader>ldp",
        function() vim.diagnostic.jump { count = -1 } end,
        { desc = "LSP go to previous issue" }
      )

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
      opts.sources.default = vim.list_extend(opts.sources.default or {}, { "lazydev" })
      opts.sources.providers = vim.tbl_deep_extend("force", opts.sources.providers or {}, {
        lazydev = {
          name = "LazyDev",
          module = "lazydev.integrations.blink",
          score_offset = 100,
        },
      })
    end,
  },
}
