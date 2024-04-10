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

M.on_attach_lsp = function(_, bufnr, _)
    -- Lspsaga finderで検索した際に各バッファで適用されるため、通知が大量に発生するためコメントアウト
    -- vim.notify("Load LSP config: " .. server_name)

    local wk = require("which-key")
    wk.register({
        m = {
            name = "LSP関連のコマンド (利用頻度: 高)",
            f = { "<cmd>Lspsaga finder<cr>", "定義/呼び出し箇所の検索" },
            i = { "<cmd>Lspsaga incoming_calls<cr>", "コールヒエラルキー (IN)"},
            o = { "<cmd>Lspsaga outgoing_calls<cr>", "コールヒエラルキー (OUT)"},
            d = { "<cmd>Lspsaga peek_definition<cr>", "定義の表示" },
            t = { "<cmd>Lspsaga peek_type_definition<cr>", "タイプ定義の表示" },
            g = {
                name = "移動",
                d = { "<cmd>Lspsaga goto_definition<cr>", "Goto definition" },
                t = { "<cmd>Lspsaga goto_type_definition<cr>", "Goto type definition" },
            },
            r = { "<cmd>Lspsaga rename<cr>", "リネーム" },
            s = { "<cmd>GitMessenger<cr>", "該当行の編集履歴を表示する" },
            h = { "<cmd>lua require('lsp_signature').toggle_float_win()<cr>", "フローティングウィンドウの表示/非表示切替" },
            n = { "<cmd>Lspsaga diagnostic_jump_next<cr>", "次のUiagnosticへ移動" },
            p = { "<cmd>Lspsaga diagnostic_jump_prev<cr>", "前のDiagnosticへ移動" },
        },
        ["<Tab>"] = { "<cmd>Lspsaga code_action<cr>", "コードアクション" },
        K = {"<cmd>Lspsaga hover_doc ++keep<CR>", "ドキュメントの表示"},
    }, {
        mode = "n",
        buffer = bufnr
    })

    wk.register({
        ['<C-s>'] = { "<cmd>lua require('lsp_signature').toggle_float_win()<cr>", "フローティングウィンドウの表示/非表示切替" },
    }, {
        mode = "i",
        buffer = bufnr
    })

    -- on_attachの利用はdeprecatedとなっているため、lsp.lua側で初期化する
    -- require("lsp_signature").on_attach({
    -- }, bufnr)
end

return M
