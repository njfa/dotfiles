local M = {}

local function is_git_repo()
    vim.fn.system("git rev-parse --is-inside-work-tree")

    return vim.v.shell_error == 0
end

local function get_git_root()
    local dot_git_path = vim.fn.finddir(".git", ".;")

    return vim.fn.fnamemodify(dot_git_path, ":h")
end

local function getcwd()
    local cwd = get_git_root()
    if cwd == '.' then
        cwd = vim.fn.getcwd()
    end
    return vim.fn.fnamemodify(cwd, ":~:.")
end

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

M.is_git_repo = function()
    return is_git_repo()
end

M.get_cwd = function()
    return getcwd()
end

M.lcd_current_workspace = function()
    if vim.bo.filetype ~= 'fern' and vim.bo.filetype ~= '' then
        local cwd = M.get_cwd()

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

M.on_attach_lsp = function(_, bufnr)
    -- フローティングウィンドウかどうかを判定し、フローティングウィンドウの場合はキーバインドを設定しない
    if M.is_floating_window() then
        return
    end

    local wk = require("which-key")
    wk.add({
        {
            mode = { "n" },
            buffer = bufnr,
            { "mf", "<cmd>Trouble lsp focus=true<cr>", desc = "定義/呼び出し箇所の検索" },
            { "mi", "<cmd>Trouble lsp_incoming_calls focus=true<cr>", desc = "コールヒエラルキー (IN)" },
            { "mo", "<cmd>Trouble lsp_outgoing_calls focus=true<cr>", desc = "コールヒエラルキー (OUT)" },
            { "mr", "<cmd>Trouble lsp_references<cr>", desc = "リファレンスの表示" },
            { "ms", function() vim.lsp.buf.rename() end, desc = "リネーム" },
            { "mn", function() vim.diagnostic.goto_next() end, desc = "次のUiagnosticへ移動" },
            { "mp", function() vim.diagnostic.goto_prev() end, desc = "前のDiagnosticへ移動" },
            { "<Tab>", "<cmd>lua vim.lsp.buf.code_action()<cr>", desc = "コードアクション" },
        }
    })
end

return M
