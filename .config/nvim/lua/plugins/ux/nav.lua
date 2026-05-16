return {
  {
    "numToStr/Navigator.nvim",
    config = function()
      require("Navigator").setup()
    end,
    keys = {
      { "<C-h>", "<CMD>NavigatorLeft<CR>" },
      { "<C-j>", "<CMD>NavigatorDown<CR>" },
      { "<C-k>", "<CMD>NavigatorUp<CR>" },
      { "<C-l>", "<CMD>NavigatorRight<CR>" },
    },
  },

  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
      { "3rd/image.nvim", cond = function() return #vim.api.nvim_list_uis() > 0 end },
    },
    keys = {
      { "<leader>e", "<Cmd>Neotree toggle<CR>", desc = "Toggle neotree explorer" },
    },
  },
}
