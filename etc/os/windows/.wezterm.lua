local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- config.term = "wezterm"

-- フォント設定（Windows Terminal settings_base.jsonから）
config.font = wezterm.font('UDEV Gothic NFLG', { weight = 'Regular' })
config.font_size = 11
config.line_height = 1.4 -- 行高を調整してガタつきを軽減
config.cell_width = 1.00
config.underline_thickness = "2px"

-- フォントのレンダリング設定
config.freetype_load_target = 'Normal' -- Light、Normal、HorizontalLcd から選択
-- config.freetype_render_target = 'Light'  -- Normal、Light、Mono、HorizontalLcd から選択
-- config.freetype_load_flags = 'NO_HINTING'  -- ヒンティングを無効化してスムーズに

-- ウィンドウの外観
config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE' -- タイトルバーを削除、タブバーは残す
config.window_padding = {
    left = 5,
    right = 5,
    top = 10,
    bottom = 0,
}

-- 初期ウィンドウサイズ
config.initial_cols = 120
config.initial_rows = 30

-- 透明度設定（Windows Terminalのopacity: 100から）
-- config.window_background_opacity = 0.9

-- Windows 10/11でのブラー効果
-- config.win32_system_backdrop = 'Acrylic'  -- Acrylic、Mica、Tabbed から選択可能
-- macOSでのブラー効果
-- config.macos_window_background_blur = 20  -- 0-100の値でブラーの強さを調整

-- タブバーの設定
config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = false
config.show_new_tab_button_in_tab_bar = true

-- タブの外観とタイトルバーの色
config.window_frame = {
    font = wezterm.font { family = 'UDEV Gothic NFLG', weight = 'Regular' },
    font_size = 10,
    active_titlebar_bg = '#141B2E',   -- 背景色と同じに設定
    inactive_titlebar_bg = '#0A0F1C', -- 少し暗めの色
    active_titlebar_fg = '#F5F5F5',   -- タイトルバーのテキスト色
    inactive_titlebar_fg = '#808080', -- 非アクティブ時のテキスト色
    button_bg = '#141B2E',            -- ボタンの背景色
    button_fg = '#808080',            -- ボタンの前景色（閉じるボタンの通常時）
    button_hover_bg = '#141B2E',      -- ホバー時のボタン背景色
    button_hover_fg = '#FFFFFF',      -- ホバー時のボタン前景色（閉じるボタンのホバー時）
}

-- カラースキーム（Windows Terminal settings_base.jsonの000000スキームから）
config.colors = {
    foreground = '#F5F5F5',
    background = '#141B2E',

    cursor_bg = '#FFFFFF',
    cursor_fg = '#141B2E',
    cursor_border = '#FFFFFF',

    selection_fg = '#141B2E',
    selection_bg = '#33467C',

    scrollbar_thumb = '#222222',

    ansi = {
        '#041024', -- black
        '#FF6B7F', -- red
        '#00BD9C', -- green
        '#E6C62F', -- yellow
        '#2640F0', -- blue
        '#DC396A', -- magenta
        '#56B6C2', -- cyan
        '#F1F1F1', -- white
    },

    brights = {
        '#4D5D80', -- bright black
        '#FE9EA1', -- bright red
        '#6FC38C', -- bright green
        '#F9E46B', -- bright yellow
        '#91FFF4', -- bright blue
        '#DA70D6', -- bright magenta
        '#BCF3FF', -- bright cyan
        '#FFFFFF', -- bright white
    },

    tab_bar = {
        background = '#0A0F1C', -- タブバー全体の背景を少し暗く
        inactive_tab_edge = '#0A0F1C',

        active_tab = {
            bg_color = '#141B2E',
            fg_color = '#F5F5F5',
            intensity = 'Normal',
            underline = 'None',
            italic = false,
            strikethrough = false,
        },

        inactive_tab = {
            bg_color = '#0A0F1C',
            fg_color = '#808080',
            intensity = 'Normal',
            underline = 'None',
            italic = false,
            strikethrough = false,
        },

        inactive_tab_hover = {
            bg_color = '#1F2A42',
            fg_color = '#B0B0B0',
            italic = false,
        },

        new_tab = {
            bg_color = '#0A0F1C',
            fg_color = '#808080',
        },

        new_tab_hover = {
            bg_color = '#1F2A42',
            fg_color = '#F5F5F5',
            italic = false,
        },
    },
}

-- その他のWindows Terminal風機能
config.audible_bell = 'Disabled'
config.default_cursor_style = 'SteadyBar'
config.scrollback_lines = 20000
config.enable_scroll_bar = true

-- 選択時にコピー（Windows Terminal settings_base.jsonから）
config.selection_word_boundary = ' ./\\()"\'`-:,.;<>~!@#$%^&*|+=[]{}~?│'

-- タブ幅モード
config.tab_max_width = 25
config.show_tab_index_in_tab_bar = true

-- タブのフォーマット設定
wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
    local title = tab.tab_title
    if title and #title > 0 then
        title = title
    else
        title = tab.active_pane.title
    end

    -- タブインデックスを追加
    local index = ''
    if config.show_tab_index_in_tab_bar then
        index = string.format('%d: ', tab.tab_index + 1)
    end

    -- 余白を追加
    return {
        { Text = '  ' .. index .. title .. '  ' },
    }
end)


-- Leaderキー設定
config.leader = { key = 'o', mods = 'CTRL', timeout_milliseconds = 1000 }

-- キーバインド設定（Windows Terminal settings_base.jsonから移植）
config.keys = {
    -- 設定を開く（Weztermでは設定ファイルを編集）
    {
        key = ',',
        mods = 'LEADER',
        action = wezterm.action.SpawnCommandInNewTab {
            args = { 'nvim', wezterm.config_file },
        }
    },
    -- コピー/ペースト
    { key = 'c',     mods = 'CTRL|SHIFT', action = wezterm.action.CopyTo 'Clipboard' },
    { key = 'v',     mods = 'CTRL|SHIFT', action = wezterm.action.PasteFrom 'Clipboard' },
    -- フォントサイズ調整
    { key = '+',     mods = 'CTRL',       action = wezterm.action.IncreaseFontSize },
    { key = '-',     mods = 'CTRL',       action = wezterm.action.DecreaseFontSize },
    { key = '0',     mods = 'CTRL',       action = wezterm.action.ResetFontSize },
    -- 検索
    { key = 'f',     mods = 'CTRL|SHIFT', action = wezterm.action.Search { CaseSensitiveString = '' } },
    -- 全画面表示（Alt+Enterは無効化）
    { key = 'Enter', mods = 'ALT',        action = wezterm.action.DisableDefaultAssignment },
    -- タブを数字キーで切り替え
    { key = '1',     mods = 'CTRL',       action = wezterm.action.ActivateTab(0) },
    { key = '2',     mods = 'CTRL',       action = wezterm.action.ActivateTab(1) },
    { key = '3',     mods = 'CTRL',       action = wezterm.action.ActivateTab(2) },
    { key = '4',     mods = 'CTRL',       action = wezterm.action.ActivateTab(3) },
    { key = '5',     mods = 'CTRL',       action = wezterm.action.ActivateTab(4) },
    { key = '6',     mods = 'CTRL',       action = wezterm.action.ActivateTab(5) },
    { key = '7',     mods = 'CTRL',       action = wezterm.action.ActivateTab(6) },
    { key = '8',     mods = 'CTRL',       action = wezterm.action.ActivateTab(7) },
    { key = '9',     mods = 'CTRL',       action = wezterm.action.ActivateTab(-1) },

    -- マルチプレクサ機能（tmux風のペイン操作）
    -- プロファイル選択メニューを表示
    { key = 'c',     mods = 'LEADER',     action = wezterm.action.ShowLauncherArgs { flags = 'FUZZY|LAUNCH_MENU_ITEMS' } },
    { key = 'c',     mods = 'ALT',        action = wezterm.action.SpawnTab 'CurrentPaneDomain' },
    -- ペイン分割
    {
        key = 'e',
        mods = 'LEADER',
        action = wezterm.action.SplitPane {
            direction = 'Right',
            size = { Percent = 50 }
        }
    },
    {
        key = 'E',
        mods = 'LEADER',
        action = wezterm.action.SplitPane {
            direction = 'Left',
            size = { Percent = 50 }
        }
    },
    {
        key = 'i',
        mods = 'LEADER',
        action = wezterm.action.SplitPane {
            direction = 'Down',
            size = { Percent = 50 }
        }
    },
    {
        key = 'I',
        mods = 'LEADER',
        action = wezterm.action.SplitPane {
            direction = 'Up',
            size = { Percent = 50 }
        }
    },

    -- ペイン間の移動（Vim風）
    { key = 'h', mods = 'ALT',       action = wezterm.action.ActivatePaneDirection 'Left' },
    { key = 'j', mods = 'ALT',       action = wezterm.action.ActivatePaneDirection 'Down' },
    { key = 'k', mods = 'ALT',       action = wezterm.action.ActivatePaneDirection 'Up' },
    { key = 'l', mods = 'ALT',       action = wezterm.action.ActivatePaneDirection 'Right' },

    -- タブの順次切り替え（tmux風）
    { key = 'n', mods = 'ALT',       action = wezterm.action.ActivateTabRelative(1) },
    { key = 'b', mods = 'ALT',       action = wezterm.action.ActivateTabRelative(-1) },

    -- ペインサイズ調整
    { key = 'H', mods = 'ALT|SHIFT', action = wezterm.action.AdjustPaneSize { 'Left', 5 } },
    { key = 'J', mods = 'ALT|SHIFT', action = wezterm.action.AdjustPaneSize { 'Down', 5 } },
    { key = 'K', mods = 'ALT|SHIFT', action = wezterm.action.AdjustPaneSize { 'Up', 5 } },
    { key = 'L', mods = 'ALT|SHIFT', action = wezterm.action.AdjustPaneSize { 'Right', 5 } },

    -- ペインを閉じる
    { key = 'x', mods = 'LEADER',    action = wezterm.action.CloseCurrentPane { confirm = false } },
    { key = 'x', mods = 'ALT',       action = wezterm.action.CloseCurrentPane { confirm = false } },

    -- コピーモード（tmux風）
    { key = 'v', mods = 'LEADER',    action = wezterm.action.ActivateCopyMode },
    { key = 'v', mods = 'ALT',       action = wezterm.action.ActivateCopyMode },

    -- ワークスペース管理（tmuxのセッション風）
    -- 新しいワークスペースを作成
    {
        key = 's',
        mods = 'LEADER',
        action = wezterm.action.PromptInputLine {
            description = 'Enter name for new workspace:',
            action = wezterm.action_callback(function(window, pane, line)
                if line then
                    window:perform_action(
                        wezterm.action.SwitchToWorkspace {
                            name = line,
                        },
                        pane
                    )
                end
            end),
        }
    },
    -- ワークスペース一覧を表示して切り替え
    { key = 'w', mods = 'LEADER', action = wezterm.action.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' } },
    -- 前のワークスペースに切り替え
    { key = '[', mods = 'LEADER', action = wezterm.action.SwitchWorkspaceRelative(-1) },
    -- 次のワークスペースに切り替え
    { key = ']', mods = 'LEADER', action = wezterm.action.SwitchWorkspaceRelative(1) },
    -- デフォルトワークスペースに戻る
    { key = 'd', mods = 'LEADER', action = wezterm.action.SwitchToWorkspace { name = 'default' } },

}

-- マウスバインド設定
config.mouse_bindings = {
    -- 右クリックでペースト
    {
        event = { Up = { streak = 1, button = 'Right' } },
        mods = 'NONE',
        action = wezterm.action.PasteFrom 'Clipboard',
    },
    -- Ctrlを押しながらクリックでURL開く
    {
        event = { Up = { streak = 1, button = 'Left' } },
        mods = 'CTRL',
        action = wezterm.action.OpenLinkAtMouseCursor,
    },
}

-- その他のWindows Terminal互換設定
config.automatically_reload_config = true
config.window_close_confirmation = 'NeverPrompt'
config.skip_close_confirmation_for_processes_named = {
    'bash',
    'sh',
    'zsh',
    'fish',
    'tmux',
    'nu',
    'cmd.exe',
    'pwsh.exe',
    'powershell.exe',
}

-- デフォルトプログラム設定（WSLを起動）
config.default_prog = { 'wsl.exe' }

-- ワークスペース設定
config.default_workspace = 'default'

-- 起動時のワークスペース選択
wezterm.on('gui-startup', function(cmd)
    local args = cmd or {}
    local workspaces = wezterm.mux.get_workspace_names()

    if #workspaces == 0 then
        -- ワークスペースがない場合、defaultを作成
        local tab, pane, window = wezterm.mux.spawn_window {
            workspace = 'default',
            args = args.args,
        }
    else
        -- ワークスペースがある場合、選択メニューを表示
        local tab, pane, window = wezterm.mux.spawn_window {
            workspace = workspaces[1], -- 一旦最初のワークスペースで起動
            args = args.args,
        }

        -- 起動後すぐにワークスペース選択メニューを表示
        window:perform_action(
            wezterm.action.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' },
            pane
        )
    end
end)

-- SSH設定を自動読み込み
config.ssh_domains = wezterm.default_ssh_domains()

-- 複数プロファイル設定（Windows Terminal風）
config.launch_menu = {
    {
        label = 'WSL (Default)',
        args = { 'wsl.exe' },
    },
    {
        label = 'Ubuntu',
        args = { 'wsl.exe', '-d', 'Ubuntu' },
    },
    {
        label = 'PowerShell 7',
        args = { 'pwsh.exe' },
    },
    {
        label = 'Command Prompt',
        args = { 'cmd.exe' },
    },
    {
        label = 'Git Bash',
        args = { 'C:\\Program Files\\Git\\bin\\bash.exe', '-l' },
    },
}

-- コピーモード専用のキーバインド
config.key_tables = {
    copy_mode = {
        -- Vim風の移動
        { key = 'h',        mods = 'NONE', action = wezterm.action.CopyMode 'MoveLeft' },
        { key = 'j',        mods = 'NONE', action = wezterm.action.CopyMode 'MoveDown' },
        { key = 'k',        mods = 'NONE', action = wezterm.action.CopyMode 'MoveUp' },
        { key = 'l',        mods = 'NONE', action = wezterm.action.CopyMode 'MoveRight' },
        -- 単語単位の移動
        { key = 'w',        mods = 'NONE', action = wezterm.action.CopyMode 'MoveForwardWord' },
        { key = 'b',        mods = 'NONE', action = wezterm.action.CopyMode 'MoveBackwardWord' },
        { key = 'e',        mods = 'NONE', action = wezterm.action.CopyMode 'MoveForwardWordEnd' },
        -- 行の端への移動
        { key = '0',        mods = 'NONE', action = wezterm.action.CopyMode 'MoveToStartOfLine' },
        { key = '$',        mods = 'SHIFT', action = wezterm.action.CopyMode 'MoveToEndOfLineContent' },
        -- ページスクロール
        { key = 'PageUp',   mods = 'NONE', action = wezterm.action.CopyMode 'PageUp' },
        { key = 'PageDown', mods = 'NONE', action = wezterm.action.CopyMode 'PageDown' },
        { key = 'd',        mods = 'CTRL', action = wezterm.action.CopyMode 'PageDown' },
        { key = 'u',        mods = 'CTRL', action = wezterm.action.CopyMode 'PageUp' },
        -- 選択開始
        { key = 'v',        mods = 'NONE', action = wezterm.action.CopyMode { SetSelectionMode = 'Cell' } },
        { key = 'V',        mods = 'NONE', action = wezterm.action.CopyMode { SetSelectionMode = 'Line' } },
        { key = 'v',        mods = 'CTRL', action = wezterm.action.CopyMode { SetSelectionMode = 'Block' } },
        -- コピーして終了
        {
            key = 'y',
            mods = 'NONE',
            action = wezterm.action.Multiple {
                wezterm.action.CopyTo 'Clipboard',
                wezterm.action.CopyMode 'Close',
            }
        },
        {
            key = 'Enter',
            mods = 'NONE',
            action = wezterm.action.Multiple {
                wezterm.action.CopyTo 'Clipboard',
                wezterm.action.CopyMode 'Close',
            }
        },
        -- 終了
        { key = 'q',         mods = 'NONE', action = wezterm.action.CopyMode 'Close' },
        { key = 'Escape',    mods = 'NONE', action = wezterm.action.CopyMode 'Close' },
        -- 検索
        { key = '/',         mods = 'NONE', action = wezterm.action.Search { CaseSensitiveString = '' } },
        { key = 'n',         mods = 'NONE', action = wezterm.action.CopyMode 'NextMatch' },
        { key = 'N',         mods = 'NONE', action = wezterm.action.CopyMode 'PriorMatch' },
    },
    search_mode = {
        {
            key = 'Enter',
            mods = 'NONE',
            action = wezterm.action.Multiple {
                wezterm.action.CopyMode 'AcceptPattern',
                wezterm.action.CopyMode 'ClearSelectionMode',
            }
        },
        {
            key = 'Escape',
            mods = 'NONE',
            action = wezterm.action.Multiple {
                wezterm.action.CopyMode 'ClearPattern',
                wezterm.action.CopyMode 'AcceptPattern',
                wezterm.action.CopyMode 'ClearSelectionMode',
            }
        },
        { key = 'UpArrow',   mods = 'NONE', action = wezterm.action.CopyMode 'PriorMatch' },
        { key = 'DownArrow', mods = 'NONE', action = wezterm.action.CopyMode 'NextMatch' },
    }
}

return config
