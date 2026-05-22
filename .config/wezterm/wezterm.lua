local config = require("wezterm").config_builder()

config.keys = {}

require("ui")(config)
require("navigator")(config)
require("pane_layout")(config)

return config
