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

-- フローティングウィンドウかどうかを判定するローカル関数
local function is_floating_window(win_id)
    local config = vim.api.nvim_win_get_config(win_id)
    return config.relative ~= ""
end

-- フローティングウィンドウかどうかを判定する
M.is_floating_window = function()
    return is_floating_window(vim.api.nvim_get_current_win())
end

-- フローティングウィンドウでない場合にコマンドを実行する
local function exec_command_not_floating_window(command)
    if not M.is_floating_window() then
        vim.api.nvim_exec2(command, {})
    else
        vim.notify("This is a floating window", vim.log.levels.WARN)
    end
end

M.on_attach_lsp = function(_, bufnr, server_name)
    -- フローティングウィンドウかどうかを判定し、フローティングウィンドウの場合はキーバインドを設定しない
    if M.is_floating_window() then
        return
    else
        vim.notify("Load LSP config: " .. server_name)
    end

    local wk = require("which-key")
    wk.register({
        m = {
            name = "LSP関連のコマンド (利用頻度: 高)",
            f = { function() exec_command_not_floating_window('Lspsaga finder') end, "定義/呼び出し箇所の検索" },
            i = { function() exec_command_not_floating_window('Lspsaga incoming_calls') end, "コールヒエラルキー (IN)"},
            o = { function() exec_command_not_floating_window('Lspsaga outgoing_calls') end, "コールヒエラルキー (OUT)"},
            d = { function() exec_command_not_floating_window('Lspsaga peek_definition') end, "定義の表示" },
            t = { function() exec_command_not_floating_window('Lspsaga peek_type_definition') end, "タイプ定義の表示" },
            g = {
                name = "移動",
                d = { function() exec_command_not_floating_window('Lspsaga goto_definition') end, "Goto definition" },
                t = { function() exec_command_not_floating_window('Lspsaga goto_type_definition') end, "Goto type definition" },
            },
            r = { function() exec_command_not_floating_window('Lspsaga rename') end, "リネーム" },
            h = { function() exec_command_not_floating_window('lua require("lsp_signature").toggle_float_win()') end, "フローティングウィンドウの表示/非表示切替" },
            n = { function() exec_command_not_floating_window('Lspsaga diagnostic_jump_next') end, "次のUiagnosticへ移動" },
            p = { function() exec_command_not_floating_window('Lspsaga diagnostic_jump_prev') end, "前のDiagnosticへ移動" },
        },
        ["<Tab>"] = { function() exec_command_not_floating_window('Lspsaga code_action') end, "コードアクション" },
        K = { function() exec_command_not_floating_window('Lspsaga hover_doc ++keep') end, "ドキュメントの表示" },
    }, {
        mode = "n",
        buffer = bufnr
    })

    -- on_attachの利用はdeprecatedとなっているため、lsp.lua側で初期化する
    -- require("lsp_signature").on_attach({
    -- }, bufnr)
end

return M
