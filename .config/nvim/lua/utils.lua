P = function(t, v)
    require("notify")(v, nil, { title = t, timeout = 2000, animate = false })
    return v
end

if pcall(require, "plenary") then
    RELOAD = require("plenary.reload").reload_module

    R = function(name)
        RELOAD(name)
        return require(name)
    end
end

-- Functional wrapper for mapping custom keybindings
function map(mode, lhs, rhs, opts)
    local options = { noremap = true }
    if opts then
        options = vim.tbl_extend("force", options, opts)
    end
    vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

function buf_map(num, mode, lhs, rhs, opts)
    local options = { noremap = true, silent = true }
    if opts then
        options = vim.tbl_extend("force", options, opts)
    end
    vim.api.nvim_buf_set_keymap(num, mode, lhs, rhs, options)
end

function lcd_current_workspace()
    if vim.bo.filetype ~= 'fern' and vim.bo.filetype ~= '' then
        vim.api.nvim_exec("lcd %:h | exec 'lcd' fnameescape(fnamemodify(finddir('.git', escape(expand('%:h'), ' ') . ';'), ':h')) | pwd", false)

        -- Fern導入済みの場合は表示を最新化
        if packer_plugins["fern.vim"] then
            vim.api.nvim_exec("Fern . -drawer -stay", false)
        end
    end
end

function find_files_from_project_git_root(opts)
    local function is_git_repo()
        vim.fn.system("git rev-parse --is-inside-work-tree")

        return vim.v.shell_error == 0
    end

    local function get_git_root()
        local dot_git_path = vim.fn.finddir(".git", ".;")

        return vim.fn.fnamemodify(dot_git_path, ":h")
    end

    if is_git_repo() then
        opts = vim.tbl_extend("force", opts, {
            cwd = get_git_root(),
        })
    end
    require("telescope.builtin").find_files(opts)
end

function live_grep_from_project_git_root(opts)
    local function is_git_repo()
        vim.fn.system("git rev-parse --is-inside-work-tree")

        return vim.v.shell_error == 0
    end

    local function get_git_root()
        local dot_git_path = vim.fn.finddir(".git", ".;")
        return vim.fn.fnamemodify(dot_git_path, ":h")
    end

    if is_git_repo() then
        opts = vim.tbl_extend("force", opts, {
            cwd = get_git_root()
        })
    end

    require("telescope.builtin").live_grep(opts)
end
