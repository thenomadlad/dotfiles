return function(config)
  config.ssh_domains = {
    {
      name = 'superbench',
      -- MagicDNS name: the bare 'superbench' resolves to the LAN first
      remote_address = 'superbench.taildc84ad.ts.net',
      username = 'aditya',
    },
  }
end
