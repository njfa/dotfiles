local map = require('common').map
local buf_map = require('common').buf_map

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

-- vim.api.nvim_create_user_command("Format", function(args)
--   local range = nil
--   if args.count ~= -1 then
--     local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
--     range = {
--       start = { args.line1, 0 },
--       ["end"] = { args.line2, end_line:len() },
--     }
--   end
--   require("conform").format({ async = true, lsp_fallback = true, range = range })
-- end, { range = true })
