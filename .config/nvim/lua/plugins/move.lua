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
    }
}
