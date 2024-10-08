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
    wk.add({
        {
            mode = { "n" },
            buffer = bufnr,
            { "mf", function() exec_command_not_floating_window('Lspsaga finder') end, desc = "定義/呼び出し箇所の検索" },
            { "mh", function() exec_command_not_floating_window('Lspsaga finder imp') end, desc = "呼び出し箇所の検索" },
            { "mi", function() exec_command_not_floating_window('Lspsaga incoming_calls') end, desc = "コールヒエラルキー (IN)" },
            { "mo", function() exec_command_not_floating_window('Lspsaga outgoing_calls') end, desc = "コールヒエラルキー (OUT)" },
            { "md", function() exec_command_not_floating_window('Lspsaga peek_definition') end, desc = "定義の表示" },
            { "mt", function() exec_command_not_floating_window('Lspsaga peek_type_definition') end, desc = "タイプ定義の表示" },
            { "gd", function() exec_command_not_floating_window('Lspsaga goto_definition') end, desc = "Goto definition" },
            { "gt", function() exec_command_not_floating_window('Lspsaga goto_type_definition') end, desc = "Goto type definition" },
            { "mr", function() exec_command_not_floating_window('Lspsaga rename') end, desc = "リネーム" },
            { "mn", function() exec_command_not_floating_window('Lspsaga diagnostic_jump_next') end, desc = "次のUiagnosticへ移動" },
            { "mp", function() exec_command_not_floating_window('Lspsaga diagnostic_jump_prev') end, desc = "前のDiagnosticへ移動" },
            { "<Tab>", function() exec_command_not_floating_window('Lspsaga code_action') end, desc = "コードアクション" },
            { "K", function() exec_command_not_floating_window('Lspsaga hover_doc') end, desc = "ドキュメントの表示" },
        }
    })

    -- on_attachの利用はdeprecatedとなっているため、lsp.lua側で初期化する
    -- require("lsp_signature").on_attach({
    -- }, bufnr)
end

return M
