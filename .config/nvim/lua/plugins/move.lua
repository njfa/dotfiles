return {
    -- easymotion likeな見た目のジャンプ機能
    {
        'smoka7/hop.nvim',
        version = '*', -- optional but strongly recommended
        opts = {
            yank_register = "*",
            keys = 'asdfghjklweruioxcvm,.'
        }
    },

    -- visualモードでhop.nvimを利用して選択範囲を変更する
    {
        'mfussenegger/nvim-treehopper',
        dependencies = {
            'smoka7/hop.nvim',
        }
    },
    {
        "folke/flash.nvim",
        event = "VeryLazy",
        config = function()
            require("flash").setup({
                labels = "asdfghjklwertyuioxcvbnm,.",
                label = {
                    uppercase = true
                },
                modes = {
                    char = {
                        keys = { "f", "F", [";"] = "<right>", [","] = "<left>" },
                    }
                }
            })
        end,
        -- opts = {},
        -- stylua: ignore
        -- keys = {
        --     { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
        --     { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
        --     { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
        --     { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
        --     { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
        -- },
    },
    {
        "andymass/vim-matchup",
        init = function()
            -- statusに設定するとnvim_context_vtと機能が被る
            -- また、popupにするとlspsagaでエラーが起きるようになるため無効化
            vim.g.matchup_matchparen_offscreen = {}
        end,
    },
}
