local map = require('common').map
-- local buf_map = require('common').buf_map

-- ファイル編集用プラグイン全般
return {
    -- "."の高機能化
    'tpope/vim-repeat',

    -- align機能の追加
    'junegunn/vim-easy-align',

    -- 単語や演算子を反対の意味に切り替える
    {
        'AndrewRadev/switch.vim',
        init = function ()
            vim.g.switch_mapping = ""
        end
    },

    -- 様々ものをincrement/decrementする
    {
        'monaqa/dial.nvim',
        config = function()
            map("n", "<C-a>", require("dial.map").inc_normal(),   {silent = true})
            map("n", "<C-x>", require("dial.map").dec_normal(),   {silent = true})
            map("n", "g<C-a>", require("dial.map").inc_gnormal(), {silent = true})
            map("n", "g<C-x>", require("dial.map").dec_gnormal(), {silent = true})
            map("v", "<C-a>", require("dial.map").inc_visual(),   {silent = true})
            map("v", "<C-x>", require("dial.map").dec_visual(),   {silent = true})
            map("v", "g<C-a>", require("dial.map").inc_gvisual(), {silent = true})
            map("v", "g<C-x>", require("dial.map").dec_gvisual(), {silent = true})
        end
    },

    -- コメント機能の拡張
    'tpope/vim-commentary',
    -- textobjectの拡張
    'wellle/targets.vim',
    -- アスタリスクを拡張
    'haya14busa/vim-asterisk',

    {
        "gbprod/substitute.nvim",
        config = function()
            require("substitute").setup({
                -- your configuration comes here
                -- or leave it empty to the default settings
                -- refer to the configuration section below
            })
        end
    },

    -- 括弧やクォートの置換機能
    {
        'machakann/vim-sandwich',
        config = function()
            vim.g.sandwich_no_default_key_mappings = 1
            vim.g.operator_sandwich_no_default_key_mappings = 1
        end
    },

    -- undoの拡張
    {
        'mbbill/undotree',
        config = function()
            -- バックアップファイルの保存場所
            if vim.fn.has('persistent_undo') ~= 0 then
                vim.opt.undodir = vim.fn.expand('~/.undo')
                vim.opt.undofile = true
            end
        end
    },

    -- TODOコメントの管理
    {
        "folke/todo-comments.nvim",
        dependencies = "nvim-lua/plenary.nvim",
        config = function()
            require("todo-comments").setup {
                -- your configuration comes here
                -- or leave it empty to the default settings
                -- refer to the configuration section below
            }
        end
    },

    -- テーブル作成用のモードを追加
    {
        'dhruvasagar/vim-table-mode',
        init = function ()
            vim.g.table_mode_map_prefix = '<Leader><Leader>t'
            -- vim.g.table_disable_mappings = 1
            vim.g.table_mode_disable_tableize_mappings = 1
            vim.g.table_mode_corner = '|'
        end
    },

    -- Gitのファイル差分を表示する
    {
        'sindrets/diffview.nvim',
        dependencies = {
            'nvim-lua/plenary.nvim'
        },
        config = function()
            -- local actions = require("diffview.actions")

            require("diffview").setup({
                keymaps = {
                    view = {
                        ["<Esc>"] = "<cmd>DiffviewClose<cr>"
                    },
                    file_panel = {
                        ["<Esc>"] = "<cmd>DiffviewClose<cr>"
                    },
                    file_history_panel  = {
                        ["<Esc>"] = "<cmd>DiffviewClose<cr>"
                    },
                }
            })
        end
    },

    {
        'hashivim/vim-terraform',
        ft = { "terraform" },
        init = function ()
            vim.g.terraform_fmt_on_save = 1
        end
    },

    {
        "iamcco/markdown-preview.nvim",
        ft = { "markdown", "plantuml" },
        build = function() vim.fn["mkdp#util#install"]() end,
        init = function()
            vim.g.mkdp_filetypes = { "markdown", "plantuml" }
        end,
        cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    },

    {
        'rhysd/git-messenger.vim',
        init = function ()
            vim.g.git_messenger_no_default_mappings = true
            vim.g.git_messenger_include_diff = "current"
            vim.g.git_messenger_floating_win_opts = { border = 'single' }
            vim.g.git_messenger_max_popup_height = 50
        end
    }
}
