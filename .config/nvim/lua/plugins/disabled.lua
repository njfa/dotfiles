return {
    -- LSP用の色定義を追加
    -- アーカイブ化されている
    -- 'folke/lsp-colors.nvim',

    -- スクロールバーを表示する
    -- 有効活用はできていなかったため無効化
    -- {
    --     'petertriho/nvim-scrollbar',
    --     config = function()
    --         local colors = require("tokyonight.colors").setup() -- pass in any of the config options as explained above

    --         require("scrollbar").setup({
    --             handle = {
    --                 color = colors.bg_highlight,
    --             },
    --             marks = {
    --                 Search = { color = colors.orange },
    --                 Error = { color = colors.error },
    --                 Warn = { color = colors.warning },
    --                 Info = { color = colors.info },
    --                 Hint = { color = colors.hint },
    --                 Misc = { color = colors.purple },
    --             }
    --         })

    --         -- scrollbarに検索がヒットした箇所を表示する
    --         require("scrollbar.handlers.search").setup()
    --     end
    -- },

    -- hlchunk.nvimを利用しているため不要
    -- {
    --     'lukas-reineke/indent-blankline.nvim',
    --     dependencies = {
    --         'nvim-treesitter/nvim-treesitter'
    --     },
    --     config = function()
    --         require('ibl').setup()
    --     end
    -- },

    -- 特に機能を利用していなかったため無効化
    -- {
    --     "folke/neodev.nvim",
    --     config = function()
    --         require("neodev").setup({
    --             library = { plugins = { "nvim-dap-ui" }, types = true },
    --         })
    --     end
    -- },

    -- TODOコメントの管理
    -- ファイル中にTODOを記入することがないため無効化
    -- {
    --     "folke/todo-comments.nvim",
    --     dependencies = "nvim-lua/plenary.nvim",
    --     config = function()
    --         require("todo-comments").setup {
    --             -- your configuration comes here
    --             -- or leave it empty to the default settings
    --             -- refer to the configuration section below
    --         }
    --     end
    -- },
}
