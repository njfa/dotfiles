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
    pattern = {"LspsagaFinder"},
    callback = function()
        buf_map(0, 'n', "<Esc>", "<cmd>lua require'lspsaga.provider'.close_lsp_finder_window()<cr>", { noremap = true })
    end,
})

vim.api.nvim_create_autocmd({"FileType"}, {
    pattern = {"LspsagaHover", "LspsagaCodeAction", "LspsagaRename" },
    callback = function()
        buf_map(0, 'n', "<Esc>", "<cmd>q<cr>", { noremap = true })
        buf_map(0, 'n', "q", "<cmd>q<cr>", { noremap = true })
    end,
})

vim.api.nvim_create_autocmd({"BufNewFile", "BufRead"}, {
    pattern = { "*.pu" },
    callback = function()
        vim.api.nvim_exec('set filetype=plantuml', false)
    end,
})
