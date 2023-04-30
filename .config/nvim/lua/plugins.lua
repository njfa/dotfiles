local ensure_packer = function()
    local fn = vim.fn
    local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
    if fn.empty(fn.glob(install_path)) > 0 then
        fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
        vim.cmd [[packadd packer.nvim]]
        return true
    end
    return false
end

local packer_bootstrap = ensure_packer()

return require('packer').startup(function(use)
    -- Packer can manage itself
    use 'wbthomason/packer.nvim'

    -- 他プラグインの依存プラグイン
    use 'nvim-lua/popup.nvim'

    -- 外観
    -- カラースキーム
    use 'relastle/bluewery.vim'
    use "EdenEast/nightfox.nvim"
    use {
        'folke/tokyonight.nvim',
        config = function()
            vim.g.tokyonight_style = "storm"
            vim.cmd("colorscheme tokyonight")
        end
    }
    -- ファイラー
    use {
        'lambdalisue/fern.vim',
        requires = {
            'antoinemadec/FixCursorHold.nvim',
        },
        config = function()
            vim.g['fern#default_hidden'] = 1
        end
    }
    use {
        'lambdalisue/fern-renderer-nerdfont.vim',
        cond = function() return packer_plugins["fern.vim"] end,
        requires = {
            'lambdalisue/fern.vim',
            'lambdalisue/nerdfont.vim'
        },
        config = function()
            vim.g['fern#renderer'] = 'nerdfont'
        end
    }
    use {
        'yuki-yano/fern-preview.vim',
        cond = function() return packer_plugins["fern.vim"] end,
        requires = {
            'lambdalisue/fern.vim',
        },
        config = function()
            -- fernでファイルにカーソルがあたった際に自動でプレビューする
            vim.g['fern_auto_preview'] = false
        end
    }
    use {
        -- fernでGitのステータスを表示
        'lambdalisue/fern-git-status.vim',
        -- nvimの標準をファイラーを置き換え
        'lambdalisue/fern-hijack.vim',
        cond = function() return packer_plugins["fern.vim"] end,
    }

    -- 現在カーソルがあたっている関数を表示する
    use {
        "SmiteshP/nvim-navic",
        requires = "neovim/nvim-lspconfig",
        config = function()
            local navic = require("nvim-navic")
            navic.setup {
                icons = {
                    File          = " ",
                    Module        = " ",
                    Namespace     = " ",
                    Package       = " ",
                    Class         = " ",
                    Method        = " ",
                    Property      = " ",
                    Field         = " ",
                    Constructor   = " ",
                    Enum          = "練",
                    Interface     = "練",
                    Function      = " ",
                    Variable      = " ",
                    Constant      = " ",
                    String        = " ",
                    Number        = " ",
                    Boolean       = "◩ ",
                    Array         = " ",
                    Object        = " ",
                    Key           = " ",
                    Null          = "ﳠ ",
                    EnumMember    = " ",
                    Struct        = " ",
                    Event         = " ",
                    Operator      = " ",
                    TypeParameter = " ",
                },
                highlight = true,
                separator = "  ",
                depth_limit = 0,
                depth_limit_indicator = "..",
            }

            vim.o.winbar = "    %{%v:lua.require'nvim-navic'.get_location()%}"
        end
    }
    -- ステータスラインをリッチな見た目にする
    use({
        "rebelot/heirline.nvim",
        config = function()
            local mod = require('plugins/heirline')
            mod.load()
        end
    })

    -- バッファーライン
    use {
        'akinsho/bufferline.nvim',
        tag = "*",
        requires = {
            'kyazdani42/nvim-web-devicons',
            -- bufferline.nvimのタブにバッファを紐づける
            'tiagovla/scope.nvim'
        },
        config = function()
            local mod = require('plugins/bufferline')
            mod.load()
        end
    }
    -- 通知をリッチな見た目にする
    use 'rcarriga/nvim-notify'
    -- nvim-lspの進捗の表示を変更する
    use {
        'j-hui/fidget.nvim',
        config = function()
            require('fidget').setup()
        end
    }
    use {
        'goolord/alpha-nvim',
        requires = { 'kyazdani42/nvim-web-devicons' },
        config = function()
            require('alpha').setup(require'alpha.themes.startify'.config)
        end
    }
    -- キーバインドをわかりやすくする
    use {
        "folke/which-key.nvim",
        config = function()
            local mod = require('plugins/which-key')
            mod.load()
        end
    }

    -- 機能拡張
    -- "."の高機能化
    use 'tpope/vim-repeat'
    -- align機能の追加
    use 'junegunn/vim-easy-align'
    -- 単語や演算子を反対の意味に切り替える
    use  'AndrewRadev/switch.vim'
    -- ターミナル表示用機能。Lspsagaにも同様の機能があるが、こちらのほうが挙動が良い
    use {
        "akinsho/toggleterm.nvim",
        tag = '*',
        config = function()
            require("toggleterm").setup()

            local Terminal  = require('toggleterm.terminal').Terminal
            local floatterm = Terminal:new({
                dir = ".",
                autochdir = true,
                direction = "float",
                hidden = true
            })

            function TermToggle()
                floatterm:toggle()
            end
            map("n", "<A-d>", "<cmd>lua TermToggle()<cr>", {})
            map("t", "<A-d>", "<cmd>lua TermToggle()<cr>", {})

            if vim.fn.executable('lazygit') == 1 then
                local lazygit = Terminal:new({
                    cmd = "lazygit",
                    dir = ".",
                    autochdir = true,
                    direction = "float",
                    hidden = true
                })

                function LazygitToggle()
                    lazygit:toggle()
                end
                map("n", "<A-g>", "<cmd>lua LazygitToggle()<cr>", {})
                map("t", "<A-g>", "<cmd>lua LazygitToggle()<cr>", {})
            end
        end
    }
    -- ファジーファインダー
    use {
        'nvim-telescope/telescope.nvim', branch = 'master',
        requires = {
            'nvim-lua/plenary.nvim',
            'nvim-telescope/telescope-frecency.nvim',
            'tami5/sqlite.lua'
        },
        config = function()
            local actions = require("telescope.actions")
            require('telescope').setup {
                defaults = {
                    layout_strategy = "vertical",
                    layout_config = {
                        horizontal = {
                            height = 0.99,
                            preview_cutoff = 40,
                            prompt_position = "bottom",
                            width = 0.99
                        },
                        vertical = {
                            height = 0.99,
                            preview_cutoff = 40,
                            prompt_position = "bottom",
                            width = 0.99
                        }
                    },
                    mappings = {
                        i = {
                            ["<esc>"] = actions.close
                        },
                    },
                    vimgrep_arguments = {
                        'rg',
                        '--with-filename',
                        '--line-number',
                        '--column',
                        '--smart-case',
                        '--no-ignore',
                        '--hidden'
                    },
                    file_ignore_patterns = {
                        "node_modules",
                        ".git",
                    }
                },
                extensions = {
                    frecency = {
                        show_scores = false,
                        ignore_patterns = {
                            "node_modules",
                            ".git",
                        },
                    }
                },
            }
        end
    }
    -- telescope.nvimでアクセス頻度の高いファイルから順に表示する
    -- コメント機能の拡張
    use 'tpope/vim-commentary'
    -- textobjectの拡張
    use 'wellle/targets.vim'
    -- undoの拡張
    use {
        'mbbill/undotree',
        config = function()
            -- バックアップファイルの保存場所
            if vim.fn.has('persistent_undo') ~= 0 then
                vim.opt.undodir = vim.fn.expand('~/.undo')
                vim.opt.undofile = true
            end
        end
    }
    -- 検索結果の表示を拡張
    use {
        'kevinhwang91/nvim-hlslens',
        config = function()
            require('hlslens').setup()
        end
    }
    -- hlslensと組み合わせて使うスクロールバー
    use {
        'petertriho/nvim-scrollbar',
        requires = {
            'folke/tokyonight.nvim',
            'kevinhwang91/nvim-hlslens'
        },
        config = function()
            local colors = require("tokyonight.colors").setup()

            require("scrollbar").setup({
                handle = {
                    color = colors.bg_highlight,
                },
                marks = {
                    Search = { color = colors.orange },
                    Error = { color = colors.error },
                    Warn = { color = colors.warning },
                    Info = { color = colors.info },
                    Hint = { color = colors.hint },
                    Misc = { color = colors.purple },
                }
            })
            require("scrollbar.handlers.search").setup()
        end
    }
    -- アスタリスクを拡張
    use 'haya14busa/vim-asterisk'
    -- easymotion likeな見た目のジャンプ機能
    use {
        'phaazon/hop.nvim',
        branch = 'v2', -- optional but strongly recommended
        config = function()
            -- you can configure Hop the way you like here; see :h hop-config
            require'hop'.setup { keys = 'etovxqpdygfblzhckisuran' }
        end
    }
    -- hop.nvimの移動先の選択肢を絞る
    use 'mfussenegger/nvim-treehopper'
    use({
        "gbprod/substitute.nvim",
        config = function()
            require("substitute").setup({
                -- your configuration comes here
                -- or leave it empty to use the default settings
                -- refer to the configuration section below
            })
        end
    })
    -- 括弧やクォートの置換機能
    use {
        'machakann/vim-sandwich',
        config = function()
            vim.g.sandwich_no_default_key_mappings = 1
            vim.g.operator_sandwich_no_default_key_mappings = 1
        end
    }
    -- Git
    use {
        'lewis6991/gitsigns.nvim',
        tag = 'v0.6', -- To use the latest release
        config = function()
            require('gitsigns').setup()
        end
    }
    -- trouble
    use {
        "folke/trouble.nvim",
        requires = "kyazdani42/nvim-web-devicons",
        config = function()
            require("trouble").setup {
                -- your configuration comes here
                -- or leave it empty to use the default settings
                -- refer to the configuration section below
            }
        end
    }
    -- TODOコメントの管理
    use {
        "folke/todo-comments.nvim",
        requires = "nvim-lua/plenary.nvim",
        config = function()
            require("todo-comments").setup {
                -- your configuration comes here
                -- or leave it empty to use the default settings
                -- refer to the configuration section below
            }
        end
    }

    -- アウトライン
    use {
        'stevearc/aerial.nvim',
        config = function() require('aerial').setup({
            backends = { "treesitter", "lsp", "markdown" },

            layout = {
                -- These control the width of the aerial window.
                -- They can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
                -- min_width and max_width can be a list of mixed types.
                -- max_width = {40, 0.2} means "the lesser of 40 columns or 20% of total"
                max_width = { 40, 0.2 },
                width = nil,
                min_width = 10,

                -- Enum: prefer_right, prefer_left, right, left, float
                -- Determines the default direction to open the aerial window. The 'prefer'
                -- options will open the window in the other direction *if* there is a
                -- different buffer in the way of the preferred direction
                default_direction = "prefer_left",

                -- Enum: edge, group, window
                --   edge   - open aerial at the far right/left of the editor
                --   group  - open aerial to the right/left of the group of windows containing the current buffer
                --   window - open aerial to the right/left of the current window
                placement = "window",
            },
            on_attach = my_aerial_on_attach
        }) end
    }

    use { 'sindrets/diffview.nvim', requires = 'nvim-lua/plenary.nvim' }

    -- Linter & Formatter
    use {
        'jose-elias-alvarez/null-ls.nvim',
        config = function()
            local null_ls = require("null-ls")
            null_ls.setup({
                sources = {
                    null_ls.builtins.formatting.stylua,
                    null_ls.builtins.diagnostics.eslint,
                    null_ls.builtins.completion.spell,
                    null_ls.builtins.formatting.prettier,
                    null_ls.builtins.diagnostics.markdownlint.with({
                        extra_args = { "--disable", "MD007", "MD012" }
                    })
                },
            })
        end
    }

    -- Treesitterの設定
    local treesitter = require('plugins/treesitter')
    treesitter.load(use)

    -- 補完の設定
    local complete = require('plugins/complete')
    complete.load(use)

    -- LSPの設定
    local lsp = require('plugins/lsp')
    lsp.load(use)

    -- プロジェクト管理
    local project = require('plugins/project')
    project.load(use)

    -- 特定言語のための拡張機能
    local markdown = require('plugins/languages/markdown')
    markdown.load(use)

    local html = require('plugins/languages/html')
    html.load(use)

    local java = require('plugins/languages/java')
    java.load(use)

    local rust = require('plugins/languages/rust')
    rust.load(use)

    -- Debuggerの設定
    local dap = require('plugins/dap')
    dap.load(use)

    if packer_bootstrap then
        require('packer').sync()
    end
end)

