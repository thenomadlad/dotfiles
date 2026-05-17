return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function(_, opts)
      require("which-key").setup(opts)
      _G.KeyVisual = require "key_visual"
    end,
    keys = {
      {
        "<leader>?",
        function() require("which-key").show { global = true } end,
        desc = "Buffer Local Keymaps (which-key)",
      },
      -- {
      --   "<leader>K",
      --   function() require("key_helper").start("n", "<leader>") end,
      --   desc = "Key helper for <leader>",
      -- },
    },
  },
}
