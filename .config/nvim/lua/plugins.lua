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
    use 'nvim-lua/plenary.nvim'
    use 'tami5/sqlite.lua'
    use 'kyazdani42/nvim-web-devicons'

    -- 機能拡張
    -- "."の高機能化
    use 'tpope/vim-repeat'
    -- align機能の追加
    use 'junegunn/vim-easy-align'
    -- 単語や演算子を反対の意味に切り替える
    use  'AndrewRadev/switch.vim'
    -- 様々ものをincrement/decrementする
    use {
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
    }
    -- コメント機能の拡張
    use 'tpope/vim-commentary'
    -- textobjectの拡張
    use 'wellle/targets.vim'
    -- アスタリスクを拡張
    use 'haya14busa/vim-asterisk'

    use {
        "gbprod/substitute.nvim",
        config = function()
            require("substitute").setup({
                -- your configuration comes here
                -- or leave it empty to use the default settings
                -- refer to the configuration section below
            })
        end
    }
    -- 括弧やクォートの置換機能
    use {
        'machakann/vim-sandwich',
        config = function()
            vim.g.sandwich_no_default_key_mappings = 1
            vim.g.operator_sandwich_no_default_key_mappings = 1
        end
    }
    -- Treesitterの設定
    require('plugins.treesitter').load(use)

    -- vscode無効化時にのみ読み込むプラグイン
    if vim.fn.exists('g:vscode') == 0 then

        -- 外観
        use {
            'kevinhwang91/nvim-hlslens',
            'petertriho/nvim-scrollbar',
            -- 通知をリッチな見た目にする
            'rcarriga/nvim-notify',
            -- nvim-lspの進捗の表示を変更する
            {
                'j-hui/fidget.nvim',
                tag = 'v1.1.0',
                config = function()
                    require('fidget').setup()
                end
            },
            {
                'akinsho/bufferline.nvim',
                requires = {
                    'kyazdani42/nvim-web-devicons',
                    'tiagovla/scope.nvim',
                }
            },
            {
                'folke/tokyonight.nvim',
                config = function()
                    require("tokyonight").setup({
                        style = "night",
                        styles = {
                            functions = {}
                        },
                        sidebars = { "qf", "vista_kind", "terminal", "packer", "fern", "sagaoutline", "aerial" },
                    })

                    local colors = require("tokyonight.colors").setup() -- pass in any of the config options as explained above

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

                    -- scrollbarに検索がヒットした箇所を表示する
                    require("scrollbar.handlers.search").setup()

                    require("plugins.bufferline").setup()

                    vim.cmd.colorscheme("tokyonight")
                end
            },
        }

        -- ファイラー
        use {
            'lambdalisue/nerdfont.vim',
            -- fernでGitのステータスを表示
            'lambdalisue/fern-git-status.vim',
            -- nvimの標準をファイラーを置き換え
            'lambdalisue/fern-hijack.vim',
            -- required nvim < 0.8
            -- 'antoinemadec/FixCursorHold.nvim',
            {
                'lambdalisue/fern.vim',
                requires = {
                    -- 'antoinemadec/FixCursorHold.nvim',
                    'lambdalisue/nerdfont.vim',
                    'lambdalisue/fern-git-status.vim',
                    'lambdalisue/fern-hijack.vim',
                },
                config = function()
                    vim.g['fern#default_hidden'] = 1


                end
            },
            {
                'lambdalisue/fern-renderer-nerdfont.vim',
                -- afterを使用しないと初回起動時にエラーが発生する
                after = 'fern.vim',
                config = function ()
                    vim.g['fern#renderer'] = 'nerdfont'
                end
            },
            {
                'yuki-yano/fern-preview.vim',
                -- afterを使用しないと初回起動時にエラーが発生する
                after = 'fern.vim',
                config = function ()
                    -- fernでファイルにカーソルがあたった際に自動でプレビューする
                    vim.g['fern_auto_preview'] = false
                end
            },
        }

        -- ステータスラインをリッチな見た目にする
        use {
            "rebelot/heirline.nvim",
            config = function()
                require('plugins.heirline').load()
            end
        }

        -- 起動時の画面をカスタマイズする
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
                require('plugins.which-key').load()
            end
        }

        -- ターミナル表示用機能。Lspsagaにも同様の機能があるが、こちらのほうが挙動が良い
        use({
            "kdheepak/lazygit.nvim",
            -- optional for floating window border decoration
            requires = {
                "nvim-lua/plenary.nvim",
            },
            config = function()
                map("n", "<A-g>", "<cmd>LazyGitCurrentFile<cr>", {})
            end
        })
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

                -- if vim.fn.executable('lazygit') == 1 then
                --     local lazygit = Terminal:new({
                --         cmd = "lazygit",
                --         dir = ".",
                --         autochdir = true,
                --         direction = "float",
                --         hidden = true
                --     })

                --     function LazygitToggle()
                --         lazygit:toggle()
                --     end
                --     map("n", "<A-g>", "<cmd>lua LazygitToggle()<cr>", {})
                --     map("t", "<A-g>", "<cmd>lua LazygitToggle()<cr>", {})
                -- end
            end
        }

        -- ファジーファインダー
        use {
            'nvim-telescope/telescope.nvim',
            branch = 'master',
            requires = {
                'nvim-lua/plenary.nvim',
                'nvim-telescope/telescope-frecency.nvim',
                'nvim-telescope/telescope-dap.nvim',
                "ahmedkhalf/project.nvim",
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
                            '--hidden',
                            '--trim'
                        },
                        file_ignore_patterns = {
                            "node_modules",
                            ".git",
                            "target"
                        }
                    },
                    extensions = {
                        frecency = {
                            db_root = vim.fn.stdpath("data"),
                            show_scores = true,
                            ignore_patterns = { "*.git/*", "*/tmp/*" },
                            use_sqlite = false,
                        }
                    },
                }

                require("project_nvim").setup {
                    -- Methods of detecting the root directory. **"lsp"** uses the native neovim
                    -- lsp, while **"pattern"** uses vim-rooter like glob pattern matching. Here
                    -- order matters: if one is not detected, the other is used as fallback. You
                    -- can also delete or rearangne the detection methods.
                    detection_methods = { "pattern", "lsp" },

                    -- All the patterns used to detect root dir, when **"pattern"** is in
                    -- detection_methods
                    patterns = { ".git", "_darcs", ".hg", ".bzr", ".svn", "Makefile", "package.json", ".env", ".gitlab-ci.yml" },

                    scope_chdir = 'tab',

                    datapath = vim.fn.stdpath("data")
                }

                require('telescope').load_extension('dap')
                require('telescope').load_extension('projects')
                require('telescope').load_extension("frecency")
            end
        }

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

        -- Git
        use {
            'lewis6991/gitsigns.nvim',
            tag = 'v0.6', -- To use the latest release
            config = function()
                require('gitsigns').setup()
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
            config = function()
                require('aerial').setup({
                    backends = { "lsp", "treesitter", "markdown", "man" },

                    layout = {
                        -- These control the width of the aerial window.
                        -- They can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
                        -- min_width and max_width can be a list of mixed types.
                        -- max_width = {40, 0.2} means "the lesser of 40 columns or 20% of total"
                        max_width = { 40, 0.2 },
                        width = nil,
                        min_width = 20,

                        -- Enum: prefer_right, prefer_left, right, left, float
                        -- Determines the default direction to open the aerial window. The 'prefer'
                        -- options will open the window in the other direction *if* there is a
                        -- different buffer in the way of the preferred direction
                        default_direction = "right",

                        -- Enum: edge, group, window
                        --   edge   - open aerial at the far right/left of the editor
                        --   group  - open aerial to the right/left of the group of windows containing the current buffer
                        --   window - open aerial to the right/left of the current window
                        placement = "window",
                    },
                    filter_kind = false,
                    -- Show box drawing characters for the tree hierarchy
                    show_guides = true,

                    on_attach = on_attach_aerial
                })

                map('n', '(', '<cmd>AerialToggle!<CR>', {})
                map('n', '<A-n>', '<cmd>AerialNavToggle<CR>', {})

            end
        }

        -- 色を可視化する
        use {
            'NvChad/nvim-colorizer.lua',
            config = function ()
                require('colorizer').setup()
            end
        }

        -- easymotion likeな見た目のジャンプ機能
        use {
            'phaazon/hop.nvim',
            branch = 'v2', -- optional but strongly recommended
            config = function()
                -- you can configure Hop the way you like here; see :h hop-config
                require'hop'.setup { keys = 'etovxqpdygfblzhckisuran' }
            end
        }
        -- visualモードでhop.nvimを利用して選択範囲を変更する
        use 'mfussenegger/nvim-treehopper'

        use { 'sindrets/diffview.nvim', requires = 'nvim-lua/plenary.nvim' }

        -- Linter & Formatter
        -- use {
        --     'jose-elias-alvarez/null-ls.nvim',
        --     config = function()
        --         local null_ls = require("null-ls")
        --         null_ls.setup({
        --             sources = {
        --                 null_ls.builtins.formatting.stylua,
        --                 null_ls.builtins.diagnostics.eslint,
        --                 null_ls.builtins.completion.spell,
        --                 null_ls.builtins.formatting.prettier,
        --                 null_ls.builtins.diagnostics.markdownlint.with({
        --                     extra_args = { "--disable", "MD007", "MD012", "MD013" }
        --                 })
        --             },
        --         })
        --     end
        -- }

        -- Debuggerの設定
        local dap = require('plugins.dap')
        dap.load(use)

        -- テーブル作成用のモードを追加
        use {
            'dhruvasagar/vim-table-mode',
            config = function ()
                vim.g.table_mode_corner='|'
            end
        }

        use {
            "iamcco/markdown-preview.nvim",
            run = "cd app && npm install",
            setup = function() vim.g.mkdp_filetypes = { "markdown", "plantuml" } end,
            ft = { "markdown", "plantuml" },
        }

        use {
            'hashivim/vim-terraform',
            setup = function ()
                vim.g.terraform_fmt_on_save = 1
            end
        }

        -- rest client
        use {
            "rest-nvim/rest.nvim",
            requires = { "nvim-lua/plenary.nvim" },
            config = function()
                require("rest-nvim").setup({
                    -- Open request results in a horizontal split
                    result_split_horizontal = false,
                    -- Keep the http file buffer above|left when split horizontal|vertical
                    result_split_in_place = false,
                    -- stay in current windows (.http file) or change to results window (default)
                    stay_in_current_window_after_split = false,
                    -- Skip SSL verification, useful for unknown certificates
                    skip_ssl_verification = false,
                    -- Encode URL before making request
                    encode_url = true,
                    -- Highlight request on run
                    highlight = {
                        enabled = true,
                        timeout = 150,
                    },
                    result = {
                        -- toggle showing URL, HTTP info, headers at top the of result window
                        show_url = true,
                        -- show the generated curl command in case you want to launch
                        -- the same request via the terminal (can be verbose)
                        show_curl_command = false,
                        show_http_info = true,
                        show_headers = true,
                        -- table of curl `--write-out` variables or false if disabled
                        -- for more granular control see Statistics Spec
                        show_statistics = false,
                        -- executables or functions for formatting response body [optional]
                        -- set them to false if you want to disable them
                        formatters = {
                            json = "jq",
                            -- html = function(body)
                            --     return vim.fn.system({"tidy", "-i", "-q", "-"}, body)
                            -- end
                        },
                    },
                    -- Jump to request line on run
                    jump_to_request = false,
                    env_file = '.env',
                    custom_dynamic_variables = {},
                    yank_dry_run = true,
                    search_back = true,
                })
            end
        }
    end

    -- 補完の設定
    local complete = require('plugins.complete')
    complete.load(use)

    -- LSPの設定
    local lsp = require('plugins.lsp')
    lsp.load(use)

    -- 特定言語のための拡張機能
    local markdown = require('plugins.languages.markdown')
    markdown.load(use)

    local html = require('plugins.languages.html')
    html.load(use)

    if packer_bootstrap then
        require('packer').sync()
    end
end)

