local M = {}

function M.load()
    -- which-key.nvimの表示間隔を狭める
    vim.opt.timeoutlen = 200
    local wk = require("which-key")
    wk.register({
        ["<leader>"] = {
            a = { name = "Toggle aerial" },
            b = { name = "[T] buffers" },
            g = { name = "[T] live_grep" },
            f = { name = "[T] find_files" },
            w = { name = "Save buffer" },
            u = { name = "Toggle undotree" },
            c = { name = "New buffer" },
            C = { name = "New tab" },
            d = { name = "Close buffer" },
            D = { name = "Close tab" },
            p = { name = "Open Trouble" },
            q = { name = "Close window" },
            Q = { name = "Close all window" },
            r = { name = "[T] frecency" },
            s = { name = "Toggle sidebar" },
            ["/"] = { name = "[T] search current buffer" },
            [":"] = { name = "[T] command history" },
        },
        ["g"] = {
            ["<Tab>"] = { name = "Lspsaga code_action" },
        },
    })
    wk.setup {
        -- your configuration comes here
        -- or leave it empty to use the default settings
        -- refer to the configuration section below
    }
end

return M;
