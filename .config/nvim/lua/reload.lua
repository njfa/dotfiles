local M = {}

function M.reload()
    local function get_module_name(s)
        local module_name;

        module_name = s:gsub("%.lua", "")
        module_name = module_name:gsub("%/", ".")
        module_name = module_name:gsub("%.init", "")

        return module_name
    end

    local prompt_title = "neovim modules"

    -- sets the path to the lua folder
    local path = "~/.dotfiles/.config/nvim/lua"

    local opts = {
        prompt_title = prompt_title,
        cwd = path,

        attach_mappings = function(_, map)
            -- Adds a new map to ctrl+e.
            map("i", "<c-e>", function(_)
                -- these two a very self-explanatory
                local entry = require("telescope.actions.state").get_selected_entry()
                local name = get_module_name(entry.value)

                -- call the helper method to reload the module
                -- and give some feedback
                R(name)
                P("Reload module: '" .. name .."'", " Success!!")
            end)

            return true
        end
    }

    -- call the builtin method to list files
    require('telescope.builtin').find_files(opts)
end

return M;
