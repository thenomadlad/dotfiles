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
}
