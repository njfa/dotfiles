local buf_map = require('common').buf_map
local vscode = require('vscode-utils')

-- IMEの自動OFF
if vim.fn.executable('zenhan.exe') == 1 then
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
        buf_map(0, 'n', "r", "<cmd>Qfreplace<cr>", { noremap = true })
        buf_map(0, 'n', "q", "<cmd>cclose<cr>", { noremap = true })
        buf_map(0, 'n', "<C-n>", "<cmd>cnewer<CR>", { noremap = true })
        buf_map(0, 'n', "<C-p>", "<cmd>colder<CR>", { noremap = true })
    end,
})

vim.api.nvim_create_autocmd({ "FileType" }, {
    pattern = { "qfreplace" },
    callback = function()
        buf_map(0, 'n', "q", "<cmd>q<cr><cmd>copen<cr>", { noremap = true })
    end,
})

-- lspsagaのUI上でESCを使えるようにする
vim.api.nvim_create_autocmd({ "FileType" }, {
    pattern = { "sagafinder" },
    callback = function()
        buf_map(0, 'n', "<Esc>", "<cmd>q<cr>", { noremap = true })
    end,
})

-- bufferlineのタブ名にcwdを設定する
vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
    pattern = { "*" },
    callback = function()
        if not vscode.is_vscode then
            local prefix = ""
            if require('picker').is_git_repo() then
                prefix = "  "
            end

            local cwd = require('picker').get_cwd()
            cwd = vim.fn.pathshorten(cwd)

            vim.api.nvim_tabpage_set_var(0, "name", prefix .. cwd)
        end
    end,
})

local reload = require("plenary.reload")

vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = "*.lua",
    callback = function(args)
        -- パスを正規化（シンボリックリンクや相対パスを解決）
        local full_path = vim.loop.fs_realpath(args.file)
        if not full_path then return end

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
