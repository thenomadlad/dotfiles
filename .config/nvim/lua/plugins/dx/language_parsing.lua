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
      "nvim-java/nvim-java",
      "mrcjkb/rustaceanvim",
      "folke/lazydev.nvim",
    },
    config = function()
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
        },
        automatic_enable = {
          exclude = { "rust_analyzer" },
        },
      }

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

      require("java").setup()
      vim.lsp.enable "jdtls"

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
      { "<leader>dc", function() require("dap").continue() end, desc = "Continue or start a debug session" },
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint on line" },
      { "<leader>drtc", function() require("dap").run_to_cursor() end, desc = "Run to cursor" },
      { "<leader>dso", function() require("dap").step_over() end, desc = "Step over" },
      { "<leader>dsi", function() require("dap").step_into() end, desc = "Step into" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate debug session" },
      { "<leader>dv", function() vim.cmd [[DapViewToggle]] end, desc = "Dap view toggle" },
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
