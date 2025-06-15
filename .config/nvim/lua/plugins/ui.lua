local map = require('common').map
local vscode_enabled, _ = pcall(require, "vscode")

local function vscode_mapping(function_native, function_vscode)
    local status_ok, vscode = pcall(require, "vscode")
    if status_ok then
        return vscode.action(function_vscode)
    else
        return function_native
    end
end


-- UI変更に関連する全般
return {
    {
        'folke/tokyonight.nvim',
        lazy = false,
        priority = 1000,
        cond = not vscode_enabled,
        config = function()
            require("tokyonight").setup({
                style = "night",
                styles = {
                    functions = {}
                },
                sidebars = { "qf", "vista_kind", "terminal", "packer", "fern", "sagaoutline", "aerial" },
            })

            vim.cmd.colorscheme("tokyonight-night")
            vim.cmd.highlight({ "Normal", "guibg=#141B2E" })
            -- vim.cmd.highlight({ "NormalSB", "guibg=#141B2E" })
            -- vim.cmd.highlight({ "NormalFloat", "guibg=#141B2E" })
            vim.cmd.highlight({ "NeoTreeNormal", "guibg=#141B2E" })
            -- vim.cmd.highlight({ "NeoTreeNormalNC", "guibg=#10172A" })
            -- vim.cmd.highlight({ "NormalNC", "guibg=#4F5258", "blend=80" })
            -- vim.cmd.highlight({ "NeoTreeNormalNC", "guibg=#4F5258", "blend=80" })
            vim.cmd.highlight({ "Float", "guibg=#141B2E" })
            vim.cmd.highlight({ "FloatTitle", "guibg=#141B2E" })
            vim.cmd.highlight({ "FloatBorder", "guibg=#141B2E" })
            vim.cmd.highlight({ "BlinkCmpMenu", "guibg=#202a42" })
            vim.cmd.highlight({ "BlinkCmpMenuSelection", "guibg=#324268" })
            vim.cmd.highlight({ "BlinkCmpDoc", "guibg=#202a42" })
            vim.cmd.highlight({ "BlinkCmpDocBorder", "guibg=#202a42" })
            vim.cmd.highlight({ "BlinkCmpDocSeparator", "guibg=#202a42" })
            vim.cmd.highlight({ "BlinkCmpSignatureHelp", "guibg=#202a42" })
            vim.cmd.highlight({ "BlinkCmpSignatureHelpBorder", "guibg=#202a42" })
            vim.cmd.highlight({ "BlinkCmpSignatureHelpActiveParameter", "guibg=#324268" })
            vim.cmd.highlight({ "SnacksBackdrop", "NONE" })
            vim.cmd.highlight({ "SnacksBackdrop_000000", "NONE" })
        end
    },

    -- 検索結果をわかりやすくする
    {
        'kevinhwang91/nvim-hlslens',
        -- cond = not vscode_enabled,
        config = function()
            require('hlslens').setup()
        end
    },

    -- Gitの変更箇所を表示する
    {
        'lewis6991/gitsigns.nvim',
        version = 'v0.7', -- To the latest release
        cond = not vscode_enabled,
        config = function()
            require('gitsigns').setup({
                current_line_blame_opts = {
                    virt_text = true,
                    virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
                    delay = 500,
                    ignore_whitespace = false,
                    virt_text_priority = 100,
                },
            })
        end
    },

    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        cond = not vscode_enabled,
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
            "MunifTanjim/nui.nvim",
            -- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
        },
        config = function()
            local function on_move(data)
                Snacks.rename.on_rename_file(data.source, data.destination)
            end
            local events = require("neo-tree.events")

            require('neo-tree').setup({
                source_selector = {
                    statusline = true, -- toggle to show selector on statusline
                    show_scrolled_off_parent_node = false, -- boolean
                    sources = { -- table
                        {
                            source = "filesystem", -- string
                            display_name = " 󰉓 Files " -- string | nil
                        },
                        {
                            source = "buffers", -- string
                            display_name = " 󰈚 Buffers " -- string | nil
                        },
                    },
                },
                close_if_last_window = true, -- Close Neo-tree if it is the last window left in the tab
                popup_border_style = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
                -- popup_border_style = { "⋅", "⋯", "⋅", "┆", "⋅", "⋯", "⋅", "┆" },
                enable_git_status = true,
                enable_diagnostics = true,
                event_handlers = {
                    { event = events.FILE_MOVED, handler = on_move },
                    { event = events.FILE_RENAMED, handler = on_move },
                },
                open_files_do_not_replace_types = { "terminal", "trouble", "qf", "sagafinder" }, -- when opening files, do not use windows containing these filetypes or buftypes
                filesystem = {
                    filtered_items = {
                        visible = false, -- when true, they will just be displayed differently than normal items
                        hide_dotfiles = false,
                        hide_gitignored = false,
                        hide_hidden = true, -- only works on Windows for hidden files/directories
                        hide_by_name = {
                            ".git"
                        },
                        hide_by_pattern = { -- uses glob style patterns
                            --"*.meta",
                            --"*/src/*/tsconfig.json",
                        },
                    },
                    follow_current_file = {
                        enabled = true,
                        leave_dirs_open = false
                    }
                },
                window = {
                    mappings = {
                        ["P"] = { "toggle_preview", config = { use_float = true, use_image_nvim = false } },
                        ["<Esc>"] = { "close_window", config = { use_float = true, use_image_nvim = false } },
                    }
                },
                buffers = {
                    window = {
                        mappings = {
                            ["d"] = "buffer_delete",
                        }
                    },
                },
            })
        end
    },


    -- ターミナルの表示
    -- Lspsagaにも同様の機能があるが、こちらのほうが挙動が良い
    {
        "akinsho/toggleterm.nvim",
        version = '*',
        cond = not vscode_enabled,
        config = function()
            require("toggleterm").setup()

            local Terminal  = require('toggleterm.terminal').Terminal
            local floatterm = Terminal:new({
                dir = ".",
                autochdir = true,
                direction = "float",
                hidden = true
            })

            function TermToggle()
                floatterm:toggle()
            end

            map("n", "<A-d>", "<cmd>lua TermToggle()<cr>", {})
            map("t", "<A-d>", "<cmd>lua TermToggle()<cr>", {})
        end
    },

    -- lazygitをカレントファイルに対して実行する
    -- toggleterm.nvimだと工夫が必要なのでこちらで実行する
    {
        "kdheepak/lazygit.nvim",
        -- optional for floating window border decoration
        cond = not vscode_enabled,
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        config = function()
            map("n", "<A-g>", "<cmd>LazyGitCurrentFile<cr>", {})
        end
    },


    -- アウトライン
    {
        'stevearc/aerial.nvim',
        cond = not vscode_enabled,
        config = function()
            require('aerial').setup({
                backends = { "lsp", "treesitter", "markdown", "man" },

                layout = {
                    -- These control the width of the aerial window.
                    -- They can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
                    -- min_width and max_width can be a list of mixed types.
                    -- max_width = {40, 0.2} means "the lesser of 40 columns or 20% of total"
                    max_width = { 40, 0.2 },
                    width = nil,
                    min_width = 20,

                    -- Enum: prefer_right, prefer_left, right, left, float
                    -- Determines the default direction to open the aerial window. The 'prefer'
                    -- options will open the window in the other direction *if* there is a
                    -- different buffer in the way of the preferred direction
                    default_direction = "right",

                    -- Enum: edge, group, window
                    --   edge   - open aerial at the far right/left of the editor
                    --   group  - open aerial to the right/left of the group of windows containing the current buffer
                    --   window - open aerial to the right/left of the current window
                    placement = "window",
                },
                filter_kind = false,
                -- Show box drawing characters for the tree hierarchy
                show_guides = true,

                on_attach = function(bufnr)
                    -- Jump forwards/backwards with '{' and '}'
                    -- Jump up the tree with '[' or ']'
                    local wk = require("which-key")
                    wk.add({
                        mode = { "n" },
                        buffer = bufnr,
                        -- { "{", "<cmd>AerialNext<CR>", desc = "Next element" },
                        -- { "}", "<cmd>AerialPrev<CR>", desc = "Prev element" },
                        -- ["["] = { "<cmd>lua require('aerial').next_up()<CR>", "Next up element"},
                        -- ["]"] = { "<cmd>lua require('aerial').prev_up()<CR>", "Prev up element"},
                    })
                end
            })

            map('n', '(', '<cmd>AerialToggle!<CR>', {})
            -- map('n', ')', '<cmd>AerialNavToggle<CR>', {})
        end
    },

    {
        'NvChad/nvim-colorizer.lua',
        cond = not vscode_enabled,
        config = function()
            require('colorizer').setup()
        end
    },

    {
        'b0o/incline.nvim',
        cond = not vscode_enabled,
        config = function()
            local helpers = require 'incline.helpers'
            local devicons = require 'nvim-web-devicons'
            require('incline').setup {
                window = {
                    padding = 0,
                    margin = { horizontal = 0 },
                },
                render = function(props)
                    local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ':t')
                    if filename == '' then
                        filename = '[No Name]'
                    end
                    local ft_icon, ft_color = devicons.get_icon_color(filename)
                    local modified = vim.bo[props.buf].modified
                    return {
                        ft_icon and { ' ', ft_icon, ' ', guibg = ft_color, guifg = helpers.contrast_color(ft_color) } or
                        '',
                        ' ',
                        { filename, gui = modified and 'bold,italic' or 'bold' },
                        ' ',
                        guibg = '#44406e',
                    }
                end,
            }
        end,
        -- Optional: Lazy load Incline
        event = 'VeryLazy',
    },

    {
        "folke/snacks.nvim",
        lazy = false,
        opts = {
            bigfile = {
                enabled = true,
                notify = true, -- show notification when big file detected
                size = 1.5 * 1024 * 1024, -- 1.5MB
            },
            dashboard = {
                enabled = true,
                width = 80,
                pane_gap = 10,
                preset = {
                    keys = {
                        { icon = " ", key = "n", desc = "新しいファイル", action = ":ene | startinsert" },
                        { icon = " ", key = "f", desc = "ファイル検索", action = ":lua Snacks.dashboard.pick('files', {hidden=true, ignored=true})" },
                        { icon = " ", key = "g", desc = "Grep検索", action = ":lua Snacks.dashboard.pick('live_grep', {hidden=true, ignored=true})" },
                        { icon = " ", key = "r", desc = "ファイル閲覧履歴", action = ":lua Snacks.dashboard.pick('oldfiles', {hidden=true, ignored=true})" },
                        { icon = " ", key = ".", desc = "設定ファイル", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config'), hidden=true, ignored=true})" },
                        { icon = " ", key = "s", desc = "セッションの再開", section = "session" },
                        { icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
                        { icon = " ", key = "q", desc = "終了", action = ":qa" },
                    }
                },
                sections = {
                    { section = "header" },
                    {
                        pane = 2,
                        section = "terminal",
                        cmd = "echo",
                        height = 8,
                        padding = 0,
                    },
                    { icon = " ", title = "ショートカット", section = "keys", indent = 2, gap = 0, padding = 1 },
                    { icon = " ", title = "最近開いたファイル", section = "recent_files", indent = 2, padding = 1 },
                    { pane = 2, icon = " ", title = "プロジェクト", section = "projects", indent = 2, padding = 1 },
                    {
                        pane = 2,
                        icon = " ",
                        title = "Gitステータス",
                        section = "terminal",
                        enabled = function()
                            return Snacks.git.get_root() ~= nil
                        end,
                        cmd = "git status --short --branch --renames",
                        height = 5,
                        padding = 1,
                        ttl = 5 * 60,
                        indent = 3,
                    },
                    { section = "startup" },
                },
            },
            dim = {},
            indent = {
                enabled = true,
                animate = {enabled=false},
                scope = {
                    enabled = true,
                    underline = false
                },
                chunk = {
                    enabled = true,
                    char = {
                        corner_top = "╭",
                        corner_bottom = "╰",
                        arrow = "─",
                    }
                }
            },
            input = { enabled = true },
            picker = {
                enabled = true,
                layout = {
                    reverse = true,
                    layout = {
                        box = "horizontal",
                        backdrop = false,
                        width = 0,
                        height = 0,
                        border = "none",
                        {
                            box = "vertical",
                            {
                                win = "preview",
                                title = "{preview:Preview}",
                                height = 15,
                                border = "rounded",
                                title_pos = "center",
                            },
                            { win = "list", title = " Results ", title_pos = "center", border = "rounded" },
                            { win = "input", height = 1, border = "rounded", title = "{title} {live} {flags}", title_pos = "center" },
                        },
                    },
                },
            },
            profiler = { enabled = true },
            scratch = { enabled = true },
            notifier = {
                enabled = true,
                -- アイコンの横幅を考慮し、スペースを追加
                style = function(buf, notif, ctx)
                    local title = vim.trim(notif.icon .. " " .. (notif.title or "")) .. " "
                    if title ~= "" then
                        ctx.opts.title = { { " " .. title .. " ", ctx.hl.title } }
                        ctx.opts.title_pos = "center"
                    end
                    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(notif.msg, "\n"))
                end
            },
            words = { enabled = true },
            win = { enabled = true },
        },
        keys = {
            { "<leader>.b",  function() Snacks.scratch() end, desc = "Toggle Scratch Buffer" },
            { "<leader>.p", function() Snacks.profiler.scratch() end, desc = "Profiler Scratch Bufferを開く" },
            { "<leader>.s",  function() Snacks.scratch.select() end, desc = "Scratch Bufferの選択" },
            { "<leader>.h", function() Snacks.picker.highlights() end, desc = "Highlight一覧" },

            { "<leader>b", function() vscode_mapping(Snacks.picker.buffers(), "workbench.files.action.focusOpenEditorsView") end, desc = "バッファ一覧" },
            { "<leader>f", function() vscode_mapping(Snacks.picker.files({hidden=true, ignored=true}), "workbench.action.quickOpen") end, desc = "ファイル検索" },
            { "<leader>g", function() vscode_mapping(Snacks.picker.grep({hidden=true, ignored=true}), "workbench.view.search") end, desc = "Grep検索" },
            { "<leader>h", function() vscode_mapping(Snacks.picker.recent({hidden=true, ignored=true}), "workbench.action.quickOpen") end, desc = "最近開いたファイル" },
            { "<leader>n", function() Snacks.picker.notifications() end, desc = "Notification History" },
            { "<leader>/", function() vscode_mapping(Snacks.picker.lines(), "workbench.action.findInFiles") end, desc = "検索 (バッファ内)" },
            { "<leader>..", function() Snacks.picker.files({ cwd = vim.fn.stdpath("config"), hidden=true, ignored=true }) end, desc = "設定ファイル一覧" },
            { "<leader>:", function() vscode_mapping(Snacks.picker.command_history({layout="vscode"}), "workbench.action.showCommands") end, desc = "コマンド履歴" },

            { "<leader><leader>f", function() Snacks.picker.git_files({hidden=true, ignored=true}) end, desc = "Gitファイル検索" },
            { "<leader><leader>g", function() Snacks.picker.git_grep({hidden=true, ignored=true}) end, desc = "Grep検索" },
            { "<leader><leader>/", function() Snacks.picker.grep_buffers() end, desc = "検索 (全バッファ内)" },

            { "<leader>s/", function() Snacks.picker.search_history() end, desc = "検索履歴" },
            { "<leader>sa", function() Snacks.picker.autocmds() end, desc = "Autocmd一覧" },
            { "<leader>sc", function() Snacks.picker.commands() end, desc = "Commands" },
            { "<leader>sd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
            { "<leader>sD", function() Snacks.picker.diagnostics_buffer() end, desc = "Buffer Diagnostics" },
            { "<leader>sh", function() Snacks.picker.help() end, desc = "Help Pages" },
            { "<leader>sH", function() Snacks.picker.highlights() end, desc = "Highlights" },
            { "<leader>si", function() Snacks.picker.icons() end, desc = "Icons" },
            { "<leader>sj", function() Snacks.picker.jumps() end, desc = "Jumps" },
            { "<leader>sk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
            { "<leader>sl", function() Snacks.picker.loclist() end, desc = "Location List" },
            { "<leader>sm", function() Snacks.picker.marks() end, desc = "Marks" },
            { "<leader>sM", function() Snacks.picker.man() end, desc = "Man Pages" },
            { "<leader>sp", function() Snacks.picker.lazy() end, desc = "Search for Plugin Spec" },
            { "<leader>sq", function() Snacks.picker.qflist() end, desc = "Quickfix List" },
            { "<leader>sR", function() Snacks.picker.resume() end, desc = "Resume" },
            { "<leader>su", function() Snacks.picker.undo() end, desc = "Undo History" },
            { "<leader>sC", function() Snacks.picker.colorschemes() end, desc = "Colorschemes" },

            { "<leader>d", function() vscode_mapping(Snacks.bufdelete(), "workbench.action.closeActiveEditor") end, desc = "バッファを閉じる" },
            { "<leader>D", function() vscode_mapping(Snacks.bufdelete.other(), "workbench.action.closeActiveEditor") end, desc = "他のバッファを全て閉じる" },
        },
        init = function()
            vim.api.nvim_create_autocmd("User", {
                pattern = "VeryLazy",
                callback = function()
                    -- Setup some globals for debugging (lazy-loaded)
                    _G.dd = function(...)
                        Snacks.debug.inspect(...)
                    end
                    _G.bt = function()
                        Snacks.debug.backtrace()
                    end
                    vim.print = _G.dd -- Override print to use snacks for `:=` command

                    -- Create some toggle mappings
                    Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
                    Snacks.toggle.option("wrap", { name = "行折り返し" }):map("<leader>uw")
                    Snacks.toggle.option("relativenumber", { name = "相対行番号" }):map("<leader>uL")
                    Snacks.toggle.diagnostics():map("<leader>ud")
                    Snacks.toggle.line_number():map("<leader>ul")
                    Snacks.toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map("<leader>uc")
                    Snacks.toggle.treesitter():map("<leader>uT")
                    Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")
                    Snacks.toggle.inlay_hints():map("<leader>uh")
                    Snacks.toggle.indent():map("<leader>ug")
                    Snacks.toggle.dim():map("<leader>uD")
                    -- Toggle the profiler
                    Snacks.toggle.profiler():map("<leader>upp")
                    -- Toggle the profiler highlights
                    Snacks.toggle.profiler_highlights():map("<leader>uph")
                end,
            })
        end,
    },
}
