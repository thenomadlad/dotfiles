return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = {
      ensure_installed = {
        "c",
        "lua",
        "vim",
        "rust",
        "vimdoc",
        "query",
        "markdown",
        "markdown_inline",
        "python",
        "java",
        "kotlin",
        "groovy",
      },
      auto_install = true,
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
      indent = {
        enable = true,
      },
    },
  },

  {
    "williamboman/mason.nvim",
    opts = {},
  },

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

  -- debugging
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "igorlfs/nvim-dap-view",
      "jay-babu/mason-nvim-dap.nvim",
      "williamboman/mason.nvim",
    },
    config = function() require("mason-nvim-dap").setup() end,
    keys = {
      { "<leader>dc",   function() require("dap").continue() end,          desc = "Continue or start a debug session" },
      { "<leader>db",   function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint on line" },
      { "<leader>drtc", function() require("dap").run_to_cursor() end,     desc = "Run to cursor" },
      { "<leader>dso",  function() require("dap").step_over() end,         desc = "Step over" },
      { "<leader>dsi",  function() require("dap").step_into() end,         desc = "Step into" },
      { "<leader>dt",   function() require("dap").terminate() end,         desc = "Terminate debug session" },
      { "<leader>dv",   function() vim.cmd [[DapViewToggle]] end,          desc = "Dap view toggle" },
      {
        "<leader>dw",
        function() vim.cmd [[DapViewWatch]] end,
        mode = { "n", "v" },
        desc = "Watch variable under cursor",
      },
    },
  },

  -- specific language configs
  {
    "mrcjkb/rustaceanvim",
    version = "^5",
    ft = "rust",
    dependencies = { "mfussenegger/nvim-dap" },
    lazy = false, -- mrcjkb feels confident he has lazy loading correctly set setup
    init = function()
      vim.g.rustaceanvim = {
        server = {
          settings = {
            ["rust-analyzer"] = {
              check = { command = "clippy" },
            },
          },
        },
      }
    end,
  },

  -- java
  {
    "mfussenegger/nvim-jdtls",
    dependencies = { "williamboman/mason.nvim" },
    opts = function(_, opts)
      -- Lazy merges opts from fragments; `cmd` may be absent until we set defaults (see lsp/jdtls.lua in nvim-jdtls).
      opts.cmd = opts.cmd or { "jdtls" }
      -- Mason's jdtls recipe ships lombok at share/jdtls/lombok.jar (stable path; Package:get_install_path is removed in Mason 2.x).
      local ok_settings, settings = pcall(require, "mason.settings")
      local ok_path, path_mod = pcall(require, "mason-core.path")
      if ok_settings and ok_path and settings.current.install_root_dir then
        local lombok_jar = path_mod.concat { settings.current.install_root_dir, "share", "jdtls", "lombok.jar" }
        if vim.uv.fs_stat(lombok_jar) then
          table.insert(opts.cmd, "--jvm-arg=-javaagent:" .. lombok_jar)
        end
      end
      -- prevent .settings, .project, etc files from being generated in the project folder
      table.insert(opts.cmd, "--jvm-arg=-Djava.import.generatesMetadataFilesAtProjectRoot=false")
      table.insert(opts.cmd, "--jvm-arg=-Xmx8G")

      opts.settings = vim.tbl_deep_extend("force", opts.settings or {}, {
        java = {
          format = {
            enabled = true,
            comments = { enabled = false },
            tabSize = 4,
          },
        },
      })
    end,
    config = function(_, opts)
      vim.lsp.config("jdtls", opts)
    end,
  },

  -- neovim development
  {
    "folke/lazydev.nvim",
    ft = "lua", -- only load on lua files
    opts = {
      library = {
        -- See the configuration section for more details
        -- Load luvit types when the `vim.uv` word is found
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

  -- comments for typescript stuff
  {
    "folke/ts-comments.nvim",
    event = "VeryLazy",
  },

  -- referencing
  {
    "romus204/referencer.nvim",
    opts = {
      enabled = true,
    },
  },
}
