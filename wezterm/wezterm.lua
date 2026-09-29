local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder()
config.default_prog = { "pwsh.exe" }
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.window_background_opacity = 0.8
config.win32_system_backdrop = "Acrylic"

config.window_frame = {
  inactive_titlebar_bg = "none",
  active_titlebar_bg = "none",
}

config.window_background_gradient = {
  colors = { "#000000" },
}

config.colors = {
  split = "#1476b8",
}

config.keys = {
  { key = "v", mods = "ALT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "-", mods = "ALT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
  { key = "h", mods = "ALT", action = act.ActivatePaneDirection("Left") },
  { key = "j", mods = "ALT", action = act.ActivatePaneDirection("Down") },
  { key = "k", mods = "ALT", action = act.ActivatePaneDirection("Up") },
  { key = "l", mods = "ALT", action = act.ActivatePaneDirection("Right") },
  { key = "H", mods = "ALT|SHIFT", action = act.AdjustPaneSize({ "Left", 5 }) },
  { key = "J", mods = "ALT|SHIFT", action = act.AdjustPaneSize({ "Down", 5 }) },
  { key = "K", mods = "ALT|SHIFT", action = act.AdjustPaneSize({ "Up", 5 }) },
  { key = "L", mods = "ALT|SHIFT", action = act.AdjustPaneSize({ "Right", 5 }) },
  { key = "z", mods = "ALT", action = act.TogglePaneZoomState },
  { key = "x", mods = "ALT", action = act.CloseCurrentPane({ confirm = true }) },
  { key = "s", mods = "ALT", action = act.PaneSelect },
}

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local background = "#5c6d74"
  local foreground = "#FFFFFF"

  if tab.is_active then
    background = "#1476b8"
    foreground = "#FFFFFF"
  end

  local label = tab.active_pane.title
  local pane_count = #wezterm.mux.get_tab(tab.tab_id):panes()
  if pane_count > 1 then
    label = label .. " [" .. pane_count .. "]"
  end
  if tab.active_pane.is_zoomed then
    label = "🔍 " .. label
  end

  local title = "   " .. wezterm.truncate_right(label, max_width - 1) .. "   "

  return {
    { Background = { Color = background } },
    { Foreground = { Color = foreground } },
    { Text = title },
  }
end)

return config
