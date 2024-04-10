return {
    -- easymotion likeな見た目のジャンプ機能
    {
        'smoka7/hop.nvim',
        version = 'v2.5.1', -- optional but strongly recommended
        opts = {
            yank_register = "*",
            keys = 'asdfghjkl:weruio'
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
        "andymass/vim-matchup",
        init = function()
            -- statusに設定するとnvim_context_vtと機能が被る
            -- また、popupにするとlspsagaでエラーが起きるようになるため無効化
            vim.g.matchup_matchparen_offscreen = {}
        end,
    },
}
