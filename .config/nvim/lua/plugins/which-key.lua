local M = {}

function M.load()
    -- which-key.nvimの表示間隔を狭める
    vim.opt.timeout = true
    vim.opt.timeoutlen = 200
    local wk = require("which-key")
    wk.register({
        ["<leader>"] = {
            f = "Telescope find_files",
            F = "Telescope find_files search_file=<input>",
            g = "Telescope live_grep",
            G = "Telescope live_grep search_file=<input>",
            r = "Telescope frecency",
            c = { '<cmd>enew<cr>', "New Buffer" },
            C = { '<cmd>tabnew<cr>', "New Tab" },
            d = { "<cmd>bp<bar>sp<bar>bn<bar>bd!<cr>", "Close buffer" },
            D = { "<Cmd>tabclose<CR>", "Close Tab" },
        }
    })
    -- wk.setup {
    --     -- your configuration comes here
    --     -- or leave it empty to use the default settings
    --     -- refer to the configuration section below
    -- }
end

return M;
