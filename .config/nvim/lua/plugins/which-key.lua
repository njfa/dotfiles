local M = {}

function M.load()
    -- which-key.nvimの表示間隔を狭める
    vim.opt.timeoutlen = 200
    local wk = require("which-key")
    wk.register({
        ["<leader>"] = {
            a = { name = "Toggle aerial" },
            b = { name = "Telescope buffers" },
            g = { name = "Telescope live_grep ignore" },
            G = { name = "Telescope live_grep no-ingnore" },
            f = { name = "Telescope find_files ignore" },
            F = { name = "Telescope find_files no-ignore" },
            w = { name = "Save buffer" },
            u = { name = "UndoTree" },
            c = { name = "Create buffer" },
            C = { name = "Create tab" },
            d = { name = "Close buffer" },
            D = { name = "Close tab" },
            p = { name = "Trouble" },
            q = { name = "Close window" },
            Q = { name = "Close all window" },
            r = { name = "Telescope frecency" },
            s = { name = "Toggle sidebar" },
            ["/"] = { name = "Telescope search current buffer" },
            [":"] = { name = "Telescope command history" },
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
