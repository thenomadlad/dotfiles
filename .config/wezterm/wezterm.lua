local config = require("wezterm").config_builder()

require("ui")(config)
require("navigator")(config)
require("ssh")(config)

return config
