local act = require('wezterm').action

return function(config)
  -- leaves the remote panes alive; `wezterm connect superbench` reattaches
  table.insert(config.keys, { key = 'd', mods = 'CTRL|SHIFT', action = act.DetachDomain 'CurrentPaneDomain' })

  config.ssh_domains = {
    {
      name = 'superbench',
      -- MagicDNS name: the bare 'superbench' resolves to the LAN first
      remote_address = 'superbench.taildc84ad.ts.net',
      username = 'aditya',
    },
  }
end
