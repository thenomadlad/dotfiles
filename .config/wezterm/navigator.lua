local wezterm = require('wezterm')
local act = wezterm.action

-- get_foreground_process_name On Linux, macOS and Windows,
-- the process can be queried to determine this path. Other operating systems
-- (notably, FreeBSD and other unix systems) are not currently supported
local function foregroundProcess(pane)
  return pane:get_foreground_process_name() or ''
end

local function runsSsh(pane)
  return foregroundProcess(pane):find('/ssh$') ~= nil
end

-- nvim handles the keys itself, and so does tmux at the far end of an ssh session
local function paneTakesNavKeys(pane)
  return foregroundProcess(pane):find('n?vim') ~= nil or runsSsh(pane) or pane:get_title():find("n?vim") ~= nil
end

local function conditionalActivatePane(window, pane, pane_direction, vim_direction)
  if paneTakesNavKeys(pane) then
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

-- At an idle zsh prompt (user var set in .zshrc), let zsh split and run the typed line.
-- Over ssh, tmux on the far end makes that call instead (see tmux.conf).
local function splitWithTypedLine(sequence, split)
  return function(window, pane)
    if pane:get_user_vars().at_prompt == '1' or runsSsh(pane) then
      window:perform_action(act.SendString(sequence), pane)
    else
      window:perform_action(split { domain = 'CurrentPaneDomain' }, pane)
    end
  end
end

wezterm.on('SplitRight', splitWithTypedLine('\x1b[37;7~', act.SplitHorizontal))
wezterm.on('SplitDown', splitWithTypedLine('\x1b[34;7~', act.SplitVertical))

return function(config)
  config.keys = {
    { key = 'h',     mods = 'CTRL',      action = act.EmitEvent('ActivatePaneDirection-left') },
    { key = 'j',     mods = 'CTRL',      action = act.EmitEvent('ActivatePaneDirection-down') },
    { key = 'k',     mods = 'CTRL',      action = act.EmitEvent('ActivatePaneDirection-up') },
    { key = 'l',     mods = 'CTRL',      action = act.EmitEvent('ActivatePaneDirection-right') },
    { key = 'Enter', mods = 'CMD',       action = act.SendString '\x1b[13;9~' },
    { key = 'Enter', mods = 'CMD|SHIFT', action = act.SendString '\x1b[13;10~' },
    { key = '%',     mods = 'CTRL|ALT',       action = act.EmitEvent('SplitRight') },
    { key = '%',     mods = 'CTRL|SHIFT|ALT', action = act.EmitEvent('SplitRight') },
    { key = '5',     mods = 'CTRL|SHIFT|ALT', action = act.EmitEvent('SplitRight') },
    { key = '"',     mods = 'CTRL|ALT',       action = act.EmitEvent('SplitDown') },
    { key = '"',     mods = 'CTRL|SHIFT|ALT', action = act.EmitEvent('SplitDown') },
    { key = "'",     mods = 'CTRL|SHIFT|ALT', action = act.EmitEvent('SplitDown') },
  }
end
