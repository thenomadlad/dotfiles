local wezterm = require('wezterm')

-- file:// links from these hosts open over ssh; any other host is treated as this Mac
local ssh_hosts = { superbench = 'aditya@superbench.taildc84ad.ts.net' }

local function unescape(s)
  return (s:gsub('%%(%x%x)', function(hex) return string.char(tonumber(hex, 16)) end))
end

-- Open a file:// link in nvim in a split to the right; some tools append :line or :line:col
local function open_file_uri(pane, uri)
  local host, path = uri:match('^file://([^/]*)(/.*)$')
  if not path then return end
  local nvim = { 'nvim' }
  local file, line = unescape(path):match('^(.-):(%d+)[:%d]*$')
  if file then
    table.insert(nvim, '+' .. line)
    path = file
  else
    path = unescape(path)
  end
  table.insert(nvim, path)

  local remote = ssh_hosts[host:lower()]
  local args
  if remote then
    args = { 'ssh', '-t', remote, wezterm.shell_join_args(nvim) }
  else
    -- interactive zsh so PATH has Homebrew's nvim; the GUI's own PATH does not
    args = { 'zsh', '-ic', 'exec "$@"', 'zsh', table.unpack(nvim) }
  end
  pane:split { direction = 'Right', args = args }
end

wezterm.on('open-uri', function(window, pane, uri)
  if uri:sub(1, 7) == 'mailto:' then
    return false
  end
  if uri:sub(1, 7) == 'file://' then
    open_file_uri(pane, uri)
    return false
  end
end)

return function(config)
  config.font_size = 13
  config.color_scheme = "Tokyo Night"

  config.tab_bar_at_bottom = true
end
