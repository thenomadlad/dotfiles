local wezterm = require('wezterm')

wezterm.on('open-uri', function(window, pane, uri)
  if uri:sub(1, 7) == 'mailto:' then
    return false
  end
end)

return function(config)
  config.font_size = 13
  config.color_scheme = "Tokyo Night"

  config.tab_bar_at_bottom = true
end
