local wezterm = require('wezterm')
local act = wezterm.action

return function(config)
  config.keys = config.keys or {}
  table.insert(config.keys, {
    key = 'u',
    mods = 'SHIFT|CTRL',
    action = wezterm.action_callback(function(window, pane)
      local tab = window:active_tab()
      local keep_id = pane:pane_id()
      local others = {}
      for _, p in ipairs(tab:panes()) do
        if p:pane_id() ~= keep_id then
          others[#others + 1] = p
        end
      end
      for _, p in ipairs(others) do
        window:perform_action(act.CloseCurrentPane({ confirm = false }), p)
      end
    end),
  })
end
