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

  -- rust
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
}
