local buf_map = require('common').buf_map

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
        local prefix = ""
        if require('picker').is_git_repo() then
            prefix = "  "
        end

        local cwd = require('picker').get_cwd()
        cwd = vim.fn.pathshorten(cwd)

        vim.api.nvim_tabpage_set_var(0, "name", prefix .. cwd)
    end,
})

local group = vim.api.nvim_create_augroup("CodeCompanionHooks", {})

-- Inlineの場合、変更的用語にフォーマットする
-- それ以外の場合、formatterが見つからずエラーになる
vim.api.nvim_create_autocmd({ "User" }, {
    pattern = { "CodeCompanionInlineFinished", "CodeCompanionDiffAttached" },
    group = group,
    callback = function(request)
        local bufnr
        if request.match == "CodeCompanionInlineFinished" then
            bufnr = request.buf
        elseif request.match == "CodeCompanionDiffAttached" then
            bufnr = request.data.bufnr
        end

        if bufnr then
            vim.notify("code formatting has begun for buffer [" .. bufnr .. "]")
            require("conform").format({
                timeout_ms = 1000,
                bufnr = bufnr,
                async = true,
            }, function(err, _)
                if err then
                    vim.notify(err, vim.log.levels.ERROR)
                else
                    vim.notify("code formatting successfully completed for buffer [" .. bufnr .. "]")
                end
            end)
        end
    end
})
