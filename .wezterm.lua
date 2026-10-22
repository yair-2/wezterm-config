-- ============================================================
-- 最简 WezTerm 配置（根目录 .wezterm.lua）
-- 三格布局 + Ctrl+Shift+方向键 切换窗格
-- ============================================================
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- 字体与大小（Cascadia Code 已安装；中英文混排自动回退）
config.font = wezterm.font_with_fallback({
    'Cascadia Code',
    'Consolas',
    'Microsoft YaHei',
    'Segoe UI Symbol',
})
config.font_size = 12.0

-- 配色
config.color_scheme = 'catppuccin-frappe'

-- 背景色：仿 cmd / Windows Terminal 的深灰（#0C0C0C，非纯黑）
-- 字体颜色：柔和绿 #33cc66
config.colors = {
    background = '#0C0C0C',
    foreground = '#33cc66',
    cursor_bg = '#33cc66',
    cursor_fg = '#0C0C0C',
    cursor_border = '#33cc66',
}

-- 光标：细竖线（SteadyBar），粗细 2px，比默认块状细很多
config.default_cursor_style = 'SteadyBar'
config.cursor_thickness = 2

-- 默认 shell：优先真实安装的 PowerShell 7（pwsh），否则 Windows PowerShell
local function default_prog()
    local candidates = {
        (os.getenv('ProgramFiles') or '') .. '\\PowerShell\\7\\pwsh.exe',
        (os.getenv('LOCALAPPDATA') or '') .. '\\Microsoft\\WindowsApps\\pwsh.exe',
    }
    for _, p in ipairs(candidates) do
        local f = io.open(p, 'r')
        if f then
            f:close()
            return { p, '-NoLogo' }
        end
    end
    return { 'powershell.exe', '-NoLogo' }
end
config.default_prog = default_prog()

-- ============================================================
-- 三格布局：左窗格 + 右半分上下
--   ┌───────────┬───────────┐
--   │           │   右上     │
--   │   左      ├───────────┤
--   │           │   右下     │
--   └───────────┴───────────┘
-- ============================================================
local function apply_three_pane_layout(pane)
    -- 左右对半，分出右半（split 返回新窗格）
    local right = pane:split({ direction = 'Right', size = 0.5 })
    -- 右半再上下对半
    right:split({ direction = 'Bottom', size = 0.5 })
end

-- 启动时第一个窗口套用三格布局
wezterm.on('gui-startup', function(cmd)
    local mux = wezterm.mux
    local tab, pane, window = mux.spawn_window(cmd or {})
    apply_three_pane_layout(pane)
end)

-- 新建标签：复用三格布局（具名事件，便于命令面板匹配快捷键提示）
wezterm.on('new-tab-three-pane', function(window, pane)
    local tab, new_pane = window:mux_window():spawn_tab({})
    apply_three_pane_layout(new_pane)
    if tab then tab:activate() end
end)

-- ============================================================
-- 快捷键
-- ============================================================
config.keys = {
    -- Ctrl+Shift+L：重载配置
    { key = 'L', mods = 'CTRL|SHIFT', action = wezterm.action.ReloadConfiguration },

    -- Ctrl+Shift+T：新建标签（三格布局）
    { key = 't', mods = 'CTRL|SHIFT', action = wezterm.action.EmitEvent('new-tab-three-pane') },

    -- Alt+Shift+\  /  Alt+Shift+-：左右 / 上下分屏
    { key = '\\', mods = 'ALT|SHIFT', action = wezterm.action.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },
    { key = '-', mods = 'ALT|SHIFT', action = wezterm.action.SplitVertical({ domain = 'CurrentPaneDomain' }) },

    -- Ctrl+Shift+K：关闭当前窗格（Ctrl+Shift+W 默认关闭当前标签）
    { key = 'K', mods = 'CTRL|SHIFT', action = wezterm.action.CloseCurrentPane({ confirm = true }) },

    -- F11：全屏
    { key = 'F11', mods = 'NONE', action = wezterm.action.ToggleFullScreen },

    -- Ctrl+Shift+方向键：切换窗格
    { key = 'LeftArrow',  mods = 'CTRL|SHIFT', action = wezterm.action.ActivatePaneDirection('Left') },
    { key = 'RightArrow', mods = 'CTRL|SHIFT', action = wezterm.action.ActivatePaneDirection('Right') },
    { key = 'UpArrow',    mods = 'CTRL|SHIFT', action = wezterm.action.ActivatePaneDirection('Up') },
    { key = 'DownArrow',  mods = 'CTRL|SHIFT', action = wezterm.action.ActivatePaneDirection('Down') },
}

-- ============================================================
-- 命令面板（Ctrl+Shift+P）：中文描述 + 右侧快捷键提示
-- 右侧提示是 WezTerm 按动作自动反向匹配按键绑定生成的，
-- 因此中文项的动作与上面的按键绑定完全一致
-- ============================================================
wezterm.on('augment-command-palette', function(window, pane)
    local act = wezterm.action
    return {
        { brief = '新建标签', action = act.EmitEvent('new-tab-three-pane') },
        { brief = '新窗口', action = act.SpawnWindow },
        { brief = '左右分屏', action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },
        { brief = '上下分屏', action = act.SplitVertical({ domain = 'CurrentPaneDomain' }) },
        { brief = '关闭当前窗格', action = act.CloseCurrentPane({ confirm = true }) },
        { brief = '关闭当前标签', action = act.CloseCurrentTab({ confirm = true }) },
        { brief = '重载配置', action = act.ReloadConfiguration },
        { brief = '复制模式', action = act.ActivateCopyMode },
        { brief = '搜索', action = act.Search('CurrentSelectionOrEmptyString') },
        { brief = '快速选择', action = act.QuickSelect },
        { brief = '全屏切换', action = act.ToggleFullScreen },
    }
end)

return config
