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
    vim.keymap.set(mode, lhs, rhs, options)
    -- vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

function buf_map(num, mode, lhs, rhs, opts)
    local options = { noremap = true, silent = true, buffer = num }
    if opts then
        options = vim.tbl_extend("force", options, opts)
    end
    vim.keymap.set(mode, lhs, rhs, options)
    -- vim.api.nvim_buf_set_keymap(num, mode, lhs, rhs, options)
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
    local utils = require('telescope.utils')
    local make_entry = require('telescope.make_entry')
    local entry_display = require('telescope.pickers.entry_display')
    local devicons = require('nvim-web-devicons')
    local def_icon = devicons.get_icon('fname', { default = true })
    local strings = require('plenary.strings')
    local iconwidth = strings.strdisplaywidth(def_icon)

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
            find_command = {
                "rg",
                "--no-ignore",
                "--hidden",
                "--files"
            }
        })
    end

    local entry_make = make_entry.gen_from_file(opts)
    opts.entry_maker = function(line)
        local entry = entry_make(line)
        local displayer = entry_display.create({
            separator = ' ',
            items = {
                { width = iconwidth },
                { width = nil },
                { remaining = true },
            },
        })
        entry.display = function(et)
            -- https://github.com/nvim-telescope/telescope.nvim/blob/master/lua/telescope/make_entry.lua
            local tail_raw, path_to_display = require('picker').get_path_and_tail(et.value)
            local tail = tail_raw .. ' '
            local icon, iconhl = utils.get_devicons(tail_raw)

            return displayer({
                { icon, iconhl },
                tail,
                { path_to_display, 'TelescopeResultsComment' },
            })
        end
        return entry
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
            cwd = get_git_root(),
            find_command = {
                'rg',
                '--with-filename',
                '--line-number',
                '--column',
                '--smart-case',
                '--no-ignore',
                '--hidden',
                '--trim'
            }
        })
    end

    require("telescope.builtin").live_grep(opts)
end
