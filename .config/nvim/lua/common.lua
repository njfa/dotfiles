local M = {}

-- Functional wrapper for mapping custom keybindings
M.map = function(mode, lhs, rhs, opts)
    local options = { noremap = true }
    if opts then
        options = vim.tbl_extend("force", options, opts)
    end
    vim.keymap.set(mode, lhs, rhs, options)
    -- vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

M.buf_map = function(num, mode, lhs, rhs, opts)
    local options = { noremap = true, silent = true, buffer = num }
    if opts then
        options = vim.tbl_extend("force", options, opts)
    end
    vim.keymap.set(mode, lhs, rhs, options)
    -- vim.api.nvim_buf_set_keymap(num, mode, lhs, rhs, options)
end

M.lcd_current_workspace = function()
    if vim.bo.filetype ~= 'fern' and vim.bo.filetype ~= '' then
        local cwd = require('picker').get_cwd()

        vim.notify("Current workspace: " .. cwd)

        -- -- Fern導入済みの場合は表示を最新化
        if pcall(vim.api.nvim_exec, "Fern . -reveal=% -drawer -stay", false) then
            vim.api.nvim_exec("Fern . -reveal=% -drawer -stay", false)
        end
    end
end

M.on_attach_lsp = function(_, bufnr, server_name)
    -- Lspsaga finderで検索した際に各バッファで適用されるため、通知が大量に発生するためコメントアウト
    -- vim.notify("Load LSP config: " .. server_name)

    local wk = require("which-key")
    wk.register({
        m = {
            f = { "<cmd>Lspsaga finder<cr>", "LSP finder" },
            c = {
                name = "Show Reference / Implementation",
                i = { "<cmd>Lspsaga incoming_calls<cr>", "Incoming_calls"},
                o = { "<cmd>Lspsaga outgoing_calls<cr>", "Outgoing_calls"}
            },
            d = { "<cmd>Lspsaga peek_definition<cr>", "Show definition" },
            t = { "<cmd>Lspsaga peek_type_definition<cr>", "Show type definition" },
            g = {
                name = "Goto Definition / Type Definition",
                d = { "<cmd>Lspsaga goto_definition<cr>", "Goto definition" },
                t = { "<cmd>Lspsaga goto_type_definition<cr>", "Goto type definition" },
            },
            r = { "<cmd>Lspsaga rename<cr>", "Rename" },
            h = { "<cmd>lua require('lsp_signature').toggle_float_win()<cr>", "Toggle float win" },
            n = { "<cmd>Lspsaga diagnostic_jump_next<cr>", "Next diagnostic" },
            p = { "<cmd>Lspsaga diagnostic_jump_prev<cr>", "Prev diagnostic" },
        },
        ["<Tab>"] = { "<cmd>Lspsaga code_action<cr>", "Code action" },
        K = {"<cmd>Lspsaga hover_doc ++keep<CR>", "show document"},
    }, {
        mode = "n",
        buffer = bufnr
    })

    require("lsp_signature").on_attach({
        bind = true,
        handler_opts = {
            border = "rounded"
        },
        hint_prefix = "󱄑 ",
    }, bufnr)
end

return M
