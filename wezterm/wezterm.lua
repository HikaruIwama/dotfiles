local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder()
config.font_dirs = { wezterm.home_dir .. "/AppData/Local/Microsoft/Windows/Fonts" }
config.font = wezterm.font("PlemolJP Console", { weight = "Medium" })
config.font_size = 12.0
config.default_prog = { "pwsh.exe" }
config.default_cwd = "C:\\dev"
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.window_background_opacity = 0.8
config.win32_system_backdrop = "Acrylic"
config.tab_max_width = 32

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

local agents = {
  { id = "claude", label = "Claude Code" },
  { id = "codex", label = "Codex" },
  { id = "opencode", label = "opencode" },
  { id = "copilot", label = "GitHub Copilot" },
}

local launch_agent = act.InputSelector({
  title = "Launch agent",
  choices = agents,
  action = wezterm.action_callback(function(window, pane, id)
    if not id then
      return
    end
    window:perform_action(
      act.SplitPane({ direction = "Right", size = { Percent = 40 }, command = { args = { id } } }),
      pane
    )
  end),
})

config.keys = {
  { key = "Enter", mods = "ALT", action = act.DisableDefaultAssignment },
  { key = "a", mods = "ALT", action = launch_agent },
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

  local prefix = ""
  if tab.active_pane.is_zoomed then
    prefix = "🔍 "
  end
  local suffix = ""
  local pane_count = #wezterm.mux.get_tab(tab.tab_id):panes()
  if pane_count > 1 then
    suffix = " [" .. pane_count .. "]"
  end

  local padding = "   "
  local available = max_width - wezterm.column_width(padding .. prefix .. suffix .. padding)
  local label = prefix .. wezterm.truncate_right(tab.active_pane.title, available) .. suffix
  local title = padding .. label .. padding

  return {
    { Background = { Color = background } },
    { Foreground = { Color = foreground } },
    { Text = title },
  }
end)

return config
