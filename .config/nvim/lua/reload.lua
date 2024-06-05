local M = {}

function M.reload()
    local prompt_title = "neovim modules"

    -- sets the path to the lua folder
    local path = "~/.dotfiles/.config/nvim/"

    local opts = {
        prompt_title = prompt_title,
        cwd = path,

        attach_mappings = function(_, map)
            -- Adds a new map to ctrl+e.
            map("i", "<c-r>", function(_)
                -- these two a very self-explanatory
                local entry = require("telescope.actions.state").get_selected_entry()
                local file_path = vim.fn.stdpath('config') .. "/" .. entry.value

                vim.api.nvim_exec("source " .. file_path, false)
                vim.notify("Reload module: " .. entry.value)
            end)

            return true
        end
    }

    -- call the builtin method to list files
    require('telescope.builtin').find_files(opts)
end

return M;
