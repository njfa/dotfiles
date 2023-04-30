local M = {}

function M.load(use)
    use {
        "ahmedkhalf/project.nvim",
        config = function()
            require("project_nvim").setup {}
            require('telescope').load_extension('projects')
        end,
    }
end

return M;
