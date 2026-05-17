return {
  -- blink as main engine
  {
    "saghen/blink.cmp",
    dependencies = {
      { "rafamadriz/friendly-snippets" },
    },
    version = "1.*",
    opts = function(_, opts) opts.keymap = { preset = "enter" } end,
  },
}
