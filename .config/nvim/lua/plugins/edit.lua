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
            local augend = require("dial.augend")
            require("dial.config").augends:register_group{
                -- default augends used when no group name is specified
                default = {
                    augend.integer.alias.decimal,   -- nonnegative decimal number (0, 1, 2, 3, ...)
                    augend.integer.alias.hex,       -- nonnegative hex number  (0x01, 0x1a1f, etc.)
                    augend.date.alias["%Y/%m/%d"],  -- date (2022/02/19, etc.)
                    augend.constant.alias.bool,    -- boolean value (true <-> false)
                    augend.constant.new{ elements = { "True", "False" } }
                }
            }

            local wk = require("which-key")
            wk.register({
                ["<C-a>"] = { require("dial.map").inc_normal(),   "インクリメント (dial.nvim)" },
                ["<C-x>"] = { require("dial.map").dec_normal(),   "デクリメント (dial.nvim)" },
                ["g<C-a>"] = { require("dial.map").inc_gnormal(), "インクリメント (dial.nvim)" },
                ["g<C-x>"] = { require("dial.map").dec_gnormal(), "デクリメント (dial.nvim)" },
            }, {
                mode = "n"
            })

            wk.register({
                ["<C-a>"] = { require("dial.map").inc_visual(),   "インクリメント (dial.nvim)" },
                ["<C-x>"] = { require("dial.map").dec_visual(),   "デクリメント (dial.nvim)" },
                ["g<C-a>"] = { require("dial.map").inc_gvisual(), "インクリメント (dial.nvim)" },
                ["g<C-x>"] = { require("dial.map").dec_gvisual(), "デクリメント (dial.nvim)" },
            }, {
                mode = "x"
            })
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
            vim.g.mkdp_preview_options = {
                uml = {
                    server = 'http://127.0.0.1:18123'
                }
            }
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
    },

    -- 対応する括弧を自動挿入する
    {
        'windwp/nvim-autopairs',
        event = "InsertEnter",
        config = true
        -- use opts = {} for passing setup options
        -- this is equalent to setup({}) function
    },

    {
        "L3MON4D3/LuaSnip",
        dependencies = {
            'rafamadriz/friendly-snippets'
        },
        -- follow latest release.
        version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
        -- install jsregexp (optional!).
        build = "make install_jsregexp"
    },

    {
        'ixru/nvim-markdown',
        dependencies = {
            "godlygeek/tabular"
        },
        init = function()
            vim.g.vim_markdown_conceal = 0
            vim.g.vim_markdown_toc_autofit = 0
        end
    },

    {
        'MeanderingProgrammer/markdown.nvim',
        name = 'render-markdown', -- Only needed if you have another plugin named markdown.nvim
        dependencies = { 'nvim-treesitter/nvim-treesitter' },
        config = function()
            require('render-markdown').setup({
                headings = {"󰼏 ", "󰎨 ", "󰼑 ", "󰎲 ", "󰼓 ", "󰎴 " },
                callout = {
                    note = '󰋽 Note ',
                    tip = '󰌶 Tip ',
                    important = '󰅾 Important ',
                    warning = '󰀪 Warning ',
                    caution = '󰳦 Caution ',
                },
                win_options = {
                    -- See :h 'conceallevel'
                    conceallevel = {
                        -- Used when not being rendered, get user setting
                        default = vim.api.nvim_get_option_value('conceallevel', {}),
                        -- Used when being rendered, concealed text is completely hidden
                        rendered = 0,
                    },
                    -- See :h 'concealcursor'
                    concealcursor = {
                        -- Used when not being rendered, get user setting
                        default = vim.api.nvim_get_option_value('concealcursor', {}),
                        -- Used when being rendered, conceal text in all modes
                        rendered = '',
                    },
                },
                highlights = {
                    heading = {
                        -- Background of heading line
                        backgrounds = {
                            'my_markdown_h1',
                            'my_markdown_h2',
                            'my_markdown_h3',
                            'my_markdown_h4',
                            'my_markdown_h5',
                            'my_markdown_h6',
                        },
                    },
                    -- Code blocks
                    code = 'my_code_block',
                },
            })
        end,
    },

    -- 対応する括弧をわかりやすくする
    {
        'haringsrob/nvim_context_vt',
        dependencies = {
            'nvim-treesitter/nvim-treesitter'
        },
        -- init = function()
        --     require("nvim-treesitter.parsers")
        -- end,
        config = function()
            require('nvim_context_vt').setup({
                -- disable_ft = {'yml', 'py'},
                disable_virtual_lines = true,
            })
        end
    },

    -- タグ入力時の補助
    {
        "windwp/nvim-ts-autotag",
        dependencies = {
            'nvim-treesitter/nvim-treesitter'
        },
        config = function()
            require("nvim-ts-autotag").setup({
                -- filetypes = { "html" , "xml", "markdown" },
            })
        end
    },

    -- ソースコードの行分割、行結合をより賢くする
    {
        'Wansmer/treesj',
        keys = { '<space>m', '<space>j', '<space>s' },
        dependencies = { 'nvim-treesitter/nvim-treesitter' },
        config = function()
            require('treesj').setup({
                use_default_keymaps = false,
                max_join_length = 1000,
            })
        end,
    },

    {
        'stevearc/conform.nvim',
        opts = {},
    }
}
