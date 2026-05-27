return {
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
      { "<leader>dbc",   function() require("dap").continue() end,          desc = "Continue or start a debug session" },
      { "<leader>dbb",   function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint on line" },
      { "<leader>dbrtc", function() require("dap").run_to_cursor() end,     desc = "Run to cursor" },
      { "<leader>dbso",  function() require("dap").step_over() end,         desc = "Step over" },
      { "<leader>dbsi",  function() require("dap").step_into() end,         desc = "Step into" },
      { "<leader>dbt",   function() require("dap").terminate() end,         desc = "Terminate debug session" },
      { "<leader>dbv",   function() vim.cmd [[DapViewToggle]] end,          desc = "Dap view toggle" },
      {
        "<leader>dbw",
        function() vim.cmd [[DapViewWatch]] end,
        mode = { "n", "v" },
        desc = "Watch variable under cursor",
      },
    },
  },
}
