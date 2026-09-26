local wezterm = require 'wezterm'

local config = wezterm.config_builder()
config.default_prog = { 'pwsh.exe' }
config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE'

return config
