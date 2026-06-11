local wezterm = require('wezterm')
local act = wezterm.action

local function isViProcess(pane)
  -- get_foreground_process_name On Linux, macOS and Windows,
  -- the process can be queried to determine this path. Other operating systems
  -- (notably, FreeBSD and other unix systems) are not currently supported
  return pane:get_foreground_process_name():find('n?vim') ~= nil or pane:get_title():find("n?vim") ~= nil
end

local function conditionalActivatePane(window, pane, pane_direction, vim_direction)
  if isViProcess(pane) then
    window:perform_action(
    -- This should match the keybinds you set in Neovim.
      act.SendKey({ key = vim_direction, mods = 'CTRL' }),
      pane
    )
  else
    window:perform_action(act.ActivatePaneDirection(pane_direction), pane)
  end
end

wezterm.on('ActivatePaneDirection-right', function(window, pane)
  conditionalActivatePane(window, pane, 'Right', 'l')
end)
wezterm.on('ActivatePaneDirection-left', function(window, pane)
  conditionalActivatePane(window, pane, 'Left', 'h')
end)
wezterm.on('ActivatePaneDirection-up', function(window, pane)
  conditionalActivatePane(window, pane, 'Up', 'k')
end)
wezterm.on('ActivatePaneDirection-down', function(window, pane)
  conditionalActivatePane(window, pane, 'Down', 'j')
end)

wezterm.on('wproj', function(window, pane)
  local right_pane = window:active_tab():active_pane()

  right_pane:split({
    direction = 'Left',
    size = 0.58,
    command = {
      args = {
        'zsh', '-c',
        'while true; do nvim .; echo "nvim exited, restarting in 2s... (Ctrl-C to stop)"; sleep 2; done'
      }
    },
  })

  -- right_pane is still the right side; split it for claude/agent on top
  right_pane:split({
    direction = 'Top',
    size = 0.5,
    command = {
      args = {
        'zsh', '-c',
        'if command -v claude >/dev/null 2>&1; then sub=claude; elif command -v agent >/dev/null 2>&1; then sub=agent; else exit; fi; while true; do $sub; echo "$sub exited, restarting in 2s... (Ctrl-C to stop)"; sleep 2; done'
      }
    },
  })
end)

return function(config)
  config.keys = {
    { key = 'h',     mods = 'CTRL',      action = act.EmitEvent('ActivatePaneDirection-left') },
    { key = 'j',     mods = 'CTRL',      action = act.EmitEvent('ActivatePaneDirection-down') },
    { key = 'k',     mods = 'CTRL',      action = act.EmitEvent('ActivatePaneDirection-up') },
    { key = 'l',     mods = 'CTRL',      action = act.EmitEvent('ActivatePaneDirection-right') },
    { key = 'Enter', mods = 'CMD',       action = act.SendString '\x1b[13;9~' },
    { key = 'Enter', mods = 'CMD|SHIFT', action = act.SendString '\x1b[13;10~' },
    -- Works in SSH sessions: new panes inherit the SSH domain, so nvim/claude run on the remote host
    { key = '{',     mods = 'CMD|SHIFT', action = act.EmitEvent('wproj') },
  }
end
