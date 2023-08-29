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

