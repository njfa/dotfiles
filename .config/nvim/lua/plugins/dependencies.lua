-- 各プラグインが依存するプラグイン
return {
    'nvim-lua/popup.nvim',

    'nvim-lua/plenary.nvim',

    'tami5/sqlite.lua',

    -- 通知の見た目を変更する
    {
        'rcarriga/nvim-notify',
        priority = 999,
        config = function()
            local notify = require("notify")
            notify.setup({
                render = "wrapped-compact",
                stages = "no_animation",
                timeout = 2000,
                top_down = false
            })
            vim.notify = notify
        end
    },

    -- nvim-lspの進捗の表示を変更する
    {
        'j-hui/fidget.nvim',
        tag = 'v1.1.0',
        config = function()
            require('fidget').setup()
        end
    },

    -- アイコンを扱えるようにする
    'nvim-tree/nvim-web-devicons',

    -- nerdfontを表示
    'lambdalisue/nerdfont.vim',

    -- バッファをタブ毎にグルーピングをする
    {
        'tiagovla/scope.nvim',
        config = function()
            require("scope").setup()
        end
    },
}
