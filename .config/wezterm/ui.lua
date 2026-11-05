local wezterm = require('wezterm')

-- file:// links from these hosts open over ssh; any other host is treated as this Mac
local ssh_hosts = { superbench = 'aditya@superbench.taildc84ad.ts.net' }

local function unescape(s)
  return (s:gsub('%%(%x%x)', function(hex) return string.char(tonumber(hex, 16)) end))
end

-- Escape a path for nvim's :edit, as fnameescape() does
local function ex_escape(path)
  return (path:gsub('[%s%*%?%[{`%$\\%%#\'"|!<]', '\\%0'))
end

-- Ctrl-\ Ctrl-N reaches normal mode from any mode (insert, cmdline, terminal), then :edit
local NVIM_KEYS = '\x1c\x0e:%s\r'

-- Runs in tmux on the remote host: hand the :edit to an nvim pane (current window first)
-- and select it, or split one off; exits 1 when no tmux server is running
local REMOTE_EDIT = [[
panes=$(tmux list-panes -s -F '#{window_active}#{pane_active} #{pane_id} #{pane_current_command}' 2>/dev/null) || exit 1
pane=$(printf '%s\n' "$panes" | awk '$3 ~ /^n?vim$/' | sort -r | awk 'NR == 1 { print $2 }')
[ -n "$pane" ] || exec tmux split-window -h nvim -c "$1"
tmux send-keys -t "$pane" 'C-\' C-n \; send-keys -t "$pane" -l ":$1" \; send-keys -t "$pane" Enter \; select-window -t "$pane" \; select-pane -t "$pane"
]]

-- ponytail: first nvim pane in the tab, not the nearest one; rank by position if that matters
local function nvim_pane(tab)
  for _, p in ipairs(tab:panes()) do
    if (p:get_foreground_process_name() or ''):find('/n?vim$') then
      return p
    end
  end
end

-- Open a file:// link in an nvim pane that is already open, else in a new split to the right.
-- Some tools append :line or :line:col to the path.
local function open_file_uri(window, pane, uri)
  local host, path = uri:match('^file://([^/]*)(/.*)$')
  if not path then return end
  path = unescape(path)
  local file, line = path:match('^(.-):(%d+)[:%d]*$')
  if file then path = file end
  local edit = 'edit ' .. (line and ('+' .. line .. ' ') or '') .. ex_escape(path)

  local remote = ssh_hosts[host:lower()]
  if remote then
    local ok = wezterm.run_child_process {
      'ssh', remote, wezterm.shell_join_args { 'sh', '-c', REMOTE_EDIT, 'sh', edit },
    }
    if not ok then
      pane:split { direction = 'Right', args = { 'ssh', '-t', remote, wezterm.shell_join_args { 'nvim', '-c', edit } } }
    end
    return
  end

  local target = nvim_pane(window:active_tab())
  if target then
    target:send_text(NVIM_KEYS:format(edit))
    target:activate()
  else
    -- interactive zsh so PATH has Homebrew's nvim; the GUI's own PATH does not
    pane:split { direction = 'Right', args = { 'zsh', '-ic', 'exec "$@"', 'zsh', 'nvim', '-c', edit } }
  end
end

wezterm.on('open-uri', function(window, pane, uri)
  if uri:sub(1, 7) == 'mailto:' then
    return false
  end
  if uri:sub(1, 7) == 'file://' then
    open_file_uri(window, pane, uri)
    return false
  end
end)

return function(config)
  config.font_size = 13
  config.color_scheme = "Tokyo Night"

  config.tab_bar_at_bottom = true
end
