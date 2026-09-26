local wezterm = require 'wezterm'

local config = wezterm.config_builder()
config.default_prog = { 'pwsh.exe' }
config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE'
config.window_background_opacity = 0.8
config.win32_system_backdrop = 'Acrylic'

return config
