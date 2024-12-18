-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

config.font_size = 12
config.color_scheme = "Tokyo Night"

-- and finally, return the configuration to wezterm
return config
