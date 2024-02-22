-- IMEの自動OFF
if vim.fn.executable('zenhan.exe') == 1 then
    vim.api.nvim_create_autocmd({"InsertLeave", "CmdlineLeave"}, {
        pattern = {"*"},
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


-- plugins.luaに記載した設定を反映
vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    pattern = { "plugins.lua" },
    callback = function()
        -- local fn = vim.fn
        -- local config_path = fn.stdpath('config') .. "/lua/plugins/**/*.lua"

        -- for _, file in ipairs(vim.split(fn.glob(config_path), '\n')) do
        --     vim.api.nvim_exec("source " .. file, false)
        --     P("Reload module: '" .. file .."'", " Success!!")
        -- end

        vim.api.nvim_exec("source <afile>", false)
        vim.api.nvim_exec('PackerCompile', false)
    end,
})

-- lspsagaのUI上でESCを使えるようにする
vim.api.nvim_create_autocmd({"FileType"}, {
    pattern = {"sagafinder"},
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

-- vim.api.nvim_create_autocmd({"FileType"}, {
--     pattern = {"saga_codeaction" },
--     callback = function()
--         buf_map(0, 'n', "<Esc>", require('lspsaga').config.code_action.keys.quit, { noremap = true })
--     end,
-- })

-- vim.api.nvim_create_autocmd({"FileType"}, {
--     pattern = {"saga_codeaction", "sagarename" },
--     callback = function()
--         buf_map(0, 'n', "<Esc>", "<cmd>q<cr>", { noremap = true })
--     end,
-- })

