local M = {}

function M.load(use)
    -- HTML入力時の補助
    use {
        "windwp/nvim-ts-autotag",
        config = function()
            require("nvim-ts-autotag").setup()
        end
    }
end

return M;
