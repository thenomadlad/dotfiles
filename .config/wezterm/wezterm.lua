local config = require("wezterm").config_builder()

require("ui")(config)
require("navigator")(config)

return config
