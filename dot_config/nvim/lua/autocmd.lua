local buf_map = require("common").buf_map
local vscode = require("vscode-utils")

local multicursor_namespace = vim.api.nvim_create_namespace("nvim.multicursor")
local multicursor_overlay_namespace = vim.api.nvim_create_namespace("dotfiles.multicursor")
local original_cursor_highlight
local original_guicursor
local multicursor_highlight_enabled = false
local multicursor_mode_colors = {
    n = "#7aa2f7",
    i = "#73daca",
    v = "#e0af68",
    V = "#ff9e64",
    ["\22"] = "#f7768e",
    c = "#9d7cd8",
    s = "#9d7cd8",
    S = "#9d7cd8",
    ["\19"] = "#9d7cd8",
    R = "#f7768e",
    r = "#f7768e",
    ["!"] = "#f7768e",
    t = "#7dcfff",
}

local function apply_multicursor_highlights()
    local color = multicursor_mode_colors[vim.fn.mode(1):sub(1, 1)] or multicursor_mode_colors.n
    vim.api.nvim_set_hl(0, "MCursor", { fg = "#1f2335", bg = color, bold = true, nocombine = true })
    vim.api.nvim_set_hl(0, "MCursorVisual", { bg = color, bold = true, nocombine = true })
    vim.api.nvim_set_hl(0, "MCursorOverlay", { fg = "#1f2335", bg = color, bold = true, nocombine = true })
end

local function update_multicursor_highlight()
    local cursors = vim.api.nvim_buf_get_extmarks(0, multicursor_namespace, 0, -1, {})
    local active = #cursors > 0

    if active then
        apply_multicursor_highlights()
    end

    vim.api.nvim_buf_clear_namespace(0, multicursor_overlay_namespace, 0, -1)
    for _, cursor in ipairs(cursors) do
        local line = vim.api.nvim_buf_get_lines(0, cursor[2], cursor[2] + 1, false)[1] or ""
        local character = vim.fn.strcharpart(line:sub(cursor[3] + 1), 0, 1)
        if character == "" or character == "\t" then
            character = " "
        end

        vim.api.nvim_buf_set_extmark(0, multicursor_overlay_namespace, cursor[2], cursor[3], {
            virt_text = { { character, "MCursorOverlay" } },
            virt_text_pos = "overlay",
            priority = 10000,
        })
    end

    if active and not multicursor_highlight_enabled then
        original_cursor_highlight = vim.api.nvim_get_hl(0, { name = "Cursor", link = true })
        original_guicursor = vim.o.guicursor
        vim.api.nvim_set_hl(0, "Cursor", { link = "MCursor" })
        vim.o.guicursor = original_guicursor .. ",a:block-MCursor"
        multicursor_highlight_enabled = true
    elseif not active and multicursor_highlight_enabled then
        vim.api.nvim_set_hl(0, "Cursor", original_cursor_highlight or {})
        vim.o.guicursor = original_guicursor or vim.o.guicursor
        original_cursor_highlight = nil
        original_guicursor = nil
        multicursor_highlight_enabled = false
    end

    vim.cmd("redraw")
end

vim.api.nvim_create_autocmd({ "CmdAtom", "BufEnter", "ModeChanged" }, {
    callback = vim.schedule_wrap(update_multicursor_highlight),
})

vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
        if multicursor_highlight_enabled then
            original_cursor_highlight = vim.api.nvim_get_hl(0, { name = "Cursor", link = true })
            apply_multicursor_highlights()
            vim.api.nvim_set_hl(0, "Cursor", { link = "MCursor" })
            vim.schedule(function()
                vim.cmd("redraw")
            end)
        end
    end,
})

-- IMEの自動OFF
if vim.fn.executable("zenhan.exe") == 1 then
    vim.api.nvim_create_autocmd({ "InsertLeave", "CmdlineLeave" }, {
        pattern = { "*" },
        command = "call system('zenhan.exe 0')",
    })
end

-- カーソル位置の復元
vim.api.nvim_create_autocmd({ "BufReadPost" }, {
    pattern = { "*" },
    callback = function()
        vim.api.nvim_exec('silent! normal! g`"zv', false)
    end,
})

-- quickfixの設定
vim.api.nvim_create_autocmd({ "FileType" }, {
    pattern = { "qf" },
    callback = function()
        buf_map(0, "n", "q", "<cmd>cclose<cr>", { noremap = true })
        buf_map(0, "n", "<C-n>", "<cmd>cnewer<CR>", { noremap = true })
        buf_map(0, "n", "<C-p>", "<cmd>colder<CR>", { noremap = true })
    end,
})

-- bufferlineのタブ名にcwdを設定する
--vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
--    pattern = { "*" },
--    callback = function()
--        if not vscode.is_vscode then
--            local prefix = ""
--            if require('picker').is_git_repo() then
--                prefix = "  "
--            end
--
--            local cwd = require('picker').get_cwd()
--            cwd = vim.fn.pathshorten(cwd)
--
--            vim.api.nvim_tabpage_set_var(0, "name", prefix .. cwd)
--        end
--    end,
--})

local reload = require("plenary.reload")

vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = "*.lua",
    callback = function(args)
        -- パスを正規化（シンボリックリンクや相対パスを解決）
        local full_path = vim.loop.fs_realpath(args.file)
        if not full_path then
            return
        end

        -- 正規化したターゲットパス
        local targets = {
            vim.loop.fs_realpath(vim.fn.expand("~/.config/nvim/lua/")),
        }

        -- 環境変数からカンマ区切りのパスを取得して追加
        local auto_reload_paths = vim.env.NVIM_LUA_AUTO_RELOAD_PATHS
        if auto_reload_paths then
            for path in auto_reload_paths:gmatch("[^,]+") do
                local trimmed_path = path:match("^%s*(.-)%s*$") -- 前後の空白を削除
                local real_path = vim.loop.fs_realpath(vim.fn.expand(trimmed_path))
                if real_path then
                    table.insert(targets, real_path)
                end
            end
        end

        local matched_root
        for _, root in ipairs(targets) do
            if full_path:sub(1, #root) == root then
                matched_root = root
                break
            end
        end

        if not matched_root then
            return -- 対象外のファイル
        end

        local relative_path = full_path:sub(#matched_root + 2) -- `/`を飛ばすため +2
        local module_name = relative_path:gsub("%.lua$", ""):gsub("/", ".")

        reload.reload_module(module_name)
        require(module_name)

        vim.notify("Reloaded: " .. module_name, vim.log.levels.INFO)
    end,
})

local progress = vim.defaulttable()
vim.api.nvim_create_autocmd("LspProgress", {
    ---@param ev {data: {client_id: integer, params: lsp.ProgressParams}}
    callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        local value = ev.data.params.value --[[@as {percentage?: number, title?: string, message?: string, kind: "begin" | "report" | "end"}]]
        if not client or type(value) ~= "table" then
            return
        end
        if value.kind ~= "end" then
            return
        end
        local p = progress[client.id]

        for i = 1, #p + 1 do
            if i == #p + 1 or p[i].token == ev.data.params.token then
                p[i] = {
                    token = ev.data.params.token,
                    msg = ("[%3d%%] %s%s"):format(
                        value.kind == "end" and 100 or value.percentage or 100,
                        value.title or "",
                        value.message and (" **%s**"):format(value.message) or ""
                    ),
                    done = value.kind == "end",
                }
                break
            end
        end

        local msg = {} ---@type string[]
        progress[client.id] = vim.tbl_filter(function(v)
            return table.insert(msg, v.msg) or not v.done
        end, p)

        local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
        vim.notify(table.concat(msg, "\n"), "info", {
            id = "lsp_progress",
            title = client.name,
            opts = function(notif)
                notif.icon = #progress[client.id] == 0 and " "
                    or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]
            end,
        })
    end,
})

-- https://zenn.dev/vim_jp/articles/ff6cd224fab0c7 を元に追加
vim.api.nvim_create_autocmd('QuitPre', {
    callback = function()
        -- 現在のウィンドウ番号を取得
        local current_win = vim.api.nvim_get_current_win()
        -- すべてのウィンドウをループして調べる
        for _, win in ipairs(vim.api.nvim_list_wins()) do
            -- カレント以外を調査
            if win ~= current_win then
                local buf = vim.api.nvim_win_get_buf(win)
                -- buftypeが空文字（通常のバッファ）があればループ終了
                if vim.bo[buf].buftype == '' then
                    return
                end
            end
        end
        -- ここまで来たらカレント以外がすべて特殊ウィンドウということなのでカレント以外をすべて閉じる
        vim.cmd.only({ bang = true })
        -- この後、ウィンドウ1つの状態でquitが実行されるので、Vimが終了する
    end,
    desc = 'Close all special buffers and quit Neovim',
})
