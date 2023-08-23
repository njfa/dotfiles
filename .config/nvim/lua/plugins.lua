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
    local treesitter = require('plugins/treesitter')
    treesitter.load(use)

    -- vscode無効化時にのみ読み込むプラグイン
    if vim.fn.exists('g:vscode') == 0 then

        -- 外観
        -- カラースキーム

        use {
            'petertriho/nvim-scrollbar',
            'kevinhwang91/nvim-hlslens',
            'lukas-reineke/indent-blankline.nvim'
        }
        use {
            'folke/tokyonight.nvim',
            requires = {
                'petertriho/nvim-scrollbar',
                'kevinhwang91/nvim-hlslens',
                'lukas-reineke/indent-blankline.nvim',
                'akinsho/bufferline.nvim',
            },
            opt = false,
            config = function()
                require("tokyonight").setup({
                    style = "night",
                    styles = {
                        functions = {}
                    },
                    sidebars = { "qf", "vista_kind", "terminal", "packer", "fern", "sagaoutline", "aerial" },
                })

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

                -- scrollbarに検索がヒットした箇所を表示する
                require("scrollbar.handlers.search").setup()

                -- インデントラインの色を設定する
                require("indent_blankline").setup {
                    show_end_of_line = true,
                    space_char_blankline = " ",
                    show_current_context = true,
                    show_current_context_start = true,
                }

                vim.cmd.colorscheme("tokyonight")
            end,
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

        -- ステータスラインをリッチな見た目にする
        use {
            "rebelot/heirline.nvim",
            config = function()
                require('plugins/heirline').load()
            end
        }

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
                require('plugins/bufferline').load()
            end
        }
        -- 通知をリッチな見た目にする
        use 'rcarriga/nvim-notify'
        -- nvim-lspの進捗の表示を変更する
        use {
            'j-hui/fidget.nvim',
            tag = 'legacy',
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
                require('plugins/which-key').load()
            end
        }

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
                'nvim-telescope/telescope-dap.nvim',
                'tami5/sqlite.lua'
            },
            config = function()
                require('telescope').load_extension('dap')

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
                            show_scores = true,
                            ignore_patterns = {
                                "node_modules",
                                ".git",
                                "target"
                            },
                        }
                    },
                }
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
        -- trouble
        -- use {
        --     "folke/trouble.nvim",
        --     requires = "kyazdani42/nvim-web-devicons",
        --     config = function()
        --         require("trouble").setup {
        --             -- your configuration comes here
        --             -- or leave it empty to use the default settings
        --             -- refer to the configuration section below
        --         }
        --     end
        -- }
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
                    placement = "group",
                },
                on_attach = on_attach_aerial
            }) end
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
        -- hop.nvimの移動先の選択肢を絞る
        use 'mfussenegger/nvim-treehopper'

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

        use {
            'mfussenegger/nvim-jdtls',
            requires = {
                'williamboman/mason.nvim',
            },
            ft = {
                "java"
            },
            config = function ()
                local jdtls_path = vim.fn.stdpath('data') .. "/mason/packages/jdtls/bin/jdtls"
                local java_debugger_path = vim.fn.stdpath('data') .. "/mason/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar"

                local cfg = {
                    cmd = { jdtls_path },
                    root_dir = vim.fs.dirname(vim.fs.find({'gradlew', '.git', 'mvnw'}, { upward = true })[1]),
                    init_options = {
                        bundles = {
                            vim.fn.glob(java_debugger_path, 1)
                        };
                    },
                    on_attach = function(client, bufnr)
                        require('jdtls').setup_dap({ hotcodereplace = 'auto' })
                    end
                }

                require('jdtls').start_or_attach(cfg)

                require('dap').configurations.java = {
                    {
                        type = 'java';
                        request = 'launch';
                        name = "Debug (Attach) - Remote";
                        hostName = '127.0.0.1';
                        port = 5005;
                    },
                }
            end
        }

        use {
            'simrat39/rust-tools.nvim',
            requires = {
                'neovim/nvim-lspconfig',
                'williamboman/mason.nvim',
            },
            ft = {
                "rust"
            },
            config = function ()
                -- local codelldb_path = require("mason-registry").get_package("codelldb"):get_install_path() .. "/extension"
                local codelldb_path = vim.fn.stdpath('data') .. "/mason/packages/codelldb/extension"
                local codelldb_bin = codelldb_path .. "/adapter/codelldb"
                local liblldb_bin = codelldb_path .. "/lldb/lib/liblldb.so"

                local rt = require('rust-tools')

                local cfg = {
                    server = {
                        settings = {
                            ['rust-analyzer'] = {
                                cargo = {
                                    autoReload = true
                                }
                            }
                        },
                    },
                    dap = {
                        adapter = require('rust-tools.dap').get_codelldb_adapter(
                            codelldb_bin,
                            liblldb_bin
                        )
                    }
                }

                rt.setup(cfg)

                -- require('dap.ext.vscode').load_launchjs(nil, {rt_lldb={'rust'}})
                require('dap').configurations.rust = {
                    {
                        type = 'rt_lldb';
                        request = 'launch';
                        name = "Debug (Attach)";
                        cwd = "${workspaceFolder}",
                        program = "${workspaceFolder}/target/debug/${workspaceFolderBasename}",
                        stopAtEntry = true,
                    },
                }
            end
        }
        -- Debuggerの設定
        local dap = require('plugins/dap')
        dap.load(use)

        -- テーブル作成用のモードを追加
        use {
            'dhruvasagar/vim-table-mode',
            config = function ()
                vim.g.table_mode_corner='|'
            end
        }
    end

    use {
        'mattn/vim-sonictemplate',
        config = function ()
            vim.g.sonictemplate_vim_template_dir = (
                "$HOME/.config/nvim/template"
            )
        end
    }

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

    use 'hashivim/vim-terraform'

    -- local java = require('plugins/languages/java')
    -- java.load(use)

    -- local rust = require('plugins/languages/rust')
    -- rust.load(use)

    if packer_bootstrap then
        require('packer').sync()
    end
end)

