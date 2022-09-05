vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
    -- Packer can manage itself
    use 'wbthomason/packer.nvim'

    -- 他プラグインの依存プラグイン
    use 'nvim-lua/popup.nvim'

    -- 外観
    -- カラースキーム
    use 'relastle/bluewery.vim'
    use "EdenEast/nightfox.nvim"
    use 'folke/tokyonight.nvim'
    -- ファイラー
    use {
        'lambdalisue/fern.vim',
        requires = {
            'antoinemadec/FixCursorHold.nvim',
            -- fernでnerdfontを使用
            'lambdalisue/nerdfont.vim',
            'lambdalisue/fern-renderer-nerdfont.vim',
            -- fernでGitのステータスを表示
            'lambdalisue/fern-git-status.vim',
            -- nvimの標準をファイラーを置き換え
            'lambdalisue/fern-hijack.vim',
            -- fernでファイルのプレビューを表示
            'yuki-yano/fern-preview.vim'
        },
        config = function()
            vim.g['fern#default_hidden'] = 1
            vim.g['fern#renderer'] = 'nerdfont'
            -- fernでファイルにカーソルがあたった際に自動でプレビューする
            vim.g['fern_auto_preview'] = false
        end
    }
    -- 現在カーソルがあたっている関数を表示する
    use {
        "SmiteshP/nvim-navic",
        requires = "neovim/nvim-lspconfig"
    }
    -- ステータスラインをリッチな見た目にする
    use {
        'nvim-lualine/lualine.nvim',
        requires = {
            'folke/tokyonight.nvim',
            -- ステータスラインに関数名を表示する
            'SmiteshP/nvim-navic',
            'kyazdani42/nvim-web-devicons', opt = true
        },
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
                highlight = false,
                separator = " > ",
                depth_limit = 0,
                depth_limit_indicator = "..",
            }
            require('lualine').setup {
                theme = 'tokyonight',
                sections = {
                    lualine_c = {
                        { navic.get_location, cond = navic.is_available },
                    }
                }
            }
        end
    }
    -- バッファーライン
    use {
        'akinsho/bufferline.nvim',
        tag = "v2.*",
        requires = {
            'kyazdani42/nvim-web-devicons',
            -- bufferline.nvimのタブにバッファを紐づける
            'tiagovla/scope.nvim'
        },
        config = function()
            require("scope").setup()

            -- ' ' ' ' ' ' ' '
            require("bufferline").setup {
                highlights = {
                    buffer_selected = {
                        bold = true,
                        italic = true,
                    },
                },
                options = {
                    indicator = {
                        -- style = 'underline'
                    },
                    diagnostics = "nvim_lsp",
                    diagnostics_indicator = function(count, level, diagnostics_dict, context)
                        local s = " "
                        for e, n in pairs(diagnostics_dict) do
                            local sym = e == "error" and " "
                            or (e == "warning" and " " or e == "info" and " " or " " )
                            s = s .. sym .. n
                        end
                        return s
                    end
                }
            }
        end
    }
    -- サイドバーを表示する
    use {
        "sidebar-nvim/sidebar.nvim",
        branch = 'dev', -- optional but strongly recommended
        config = function()
            require('sidebar-nvim').setup({
                bindings = {
                    ['q'] = function()
                        require('sidebar-nvim').close()
                    end,
                    ['<Esc>'] = function()
                        require('sidebar-nvim').close()
                    end
                },
                open = false,
                initial_width = 30,
                hide_statusline = true,
                section_separator = '',
                sections = {'buffers', 'git', 'todos'},
                todos = {
                    icon = "",
                    ignored_paths = {'~'}, -- ignore certain paths, this will prevent huge folders like $HOME to hog Neovim with TODO searching
                    initially_closed = true, -- whether the groups should be initially closed on start. You can manually open/close groups later.
                },
                buffers = {
                    icon = "",
                    ignored_buffers = {}, -- ignore buffers by regex
                    sorting = "id", -- alternatively set it to "name" to sort by buffer name instead of buf id
                    show_numbers = true, -- whether to also show the buffer numbers
                    ignore_not_loaded = true, -- whether to ignore not loaded buffers
                    ignore_terminal = true, -- whether to show terminal buffers in the list
                }
            })
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
    -- 対応する括弧をわかりやすくする
    use 'haringsrob/nvim_context_vt'
    -- キーバインドをわかりやすくする
    use {
        "folke/which-key.nvim",
        config = function()
            -- which-key.nvimの表示間隔を狭める
            vim.opt.timeoutlen = 200
            local wk = require("which-key")
            wk.register({
                ["<leader>"] = {
                    f = { name = "Find File" },
                    x = { name = "Close Tab" },
                    w = { name = "Save File" },
                    u = { name = "Toggle Undotree" },
                    c = { name = "Create Buffer" },
                    r = { name = "Open Recent File" },
                    q = { name = "Close Window" },
                    p = { name = "Toggle Diagnostics" },
                    g = { name = "Live Grep" },
                    e = { name = "Open Fern" },
                    d = { name = "Close Buffer" },
                    b = { name = "Find Buffer" },
                    a = { name = "Toggle Aerial" },
                    s = { name = "Toggle Sidebar" },
                    t = { name = "Create Tab" },
                    ["/"] = { name = "Search Current Buffer" },
                    [":"] = { name = "Command History" },
                },
            })
            wk.setup {
                -- your configuration comes here
                -- or leave it empty to use the default settings
                -- refer to the configuration section below
            }
        end
    }

    -- 機能拡張
    -- "."の高機能化
    use 'tpope/vim-repeat'
    -- align機能の追加
    -- use 'Vonr/align.nvim'
    use 'junegunn/vim-easy-align'
    -- 単語や演算子を反対の意味に切り替える
    use  'AndrewRadev/switch.vim'
    -- ファジーファインダー
    use {
        'nvim-telescope/telescope.nvim', tag = '0.1.0',
        requires = {
            'nvim-lua/plenary.nvim',
            'nvim-telescope/telescope-frecency.nvim',
            "tami5/sqlite.lua"
        },
        config = function()
            require("telescope").load_extension("frecency")

            local actions = require("telescope.actions")
            require('telescope').setup {
                defaults = {
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
                        ignore_patterns = {"*.git/*"},
                        workspaces = {
                            ["project"] = "~/projects",
                            ["dotfiles"]    = "~/.dotfiles"
                        }
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
                vim.opt.undodir = vim.fn.expand('~/.config/nvim/undo')
                vim.opt.undofile = true
            end
        end
    }
    -- 検索結果の表示を拡張
    use 'kevinhwang91/nvim-hlslens'
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
    -- treesitter
    use {
        'nvim-treesitter/nvim-treesitter',
        run = ':TSUpdate',
        config = function()
            require'nvim-treesitter.configs'.setup {
                -- A list of parser names, or "all"
                ensure_installed = { "lua", "rust" },

                -- Install parsers synchronously (only applied to `ensure_installed`)
                sync_install = false,

                -- Automatically install missing parsers when entering buffer
                auto_install = true,

                -- List of parsers to ignore installing (for "all")
                -- ignore_install = { "javascript" },

                ---- If you need to change the installation directory of the parsers (see -> Advanced Setup)
                -- parser_install_dir = "/some/path/to/store/parsers", -- Remember to run vim.opt.runtimepath:append("/some/path/to/store/parsers")!

                highlight = {
                    -- `false` will disable the whole extension
                    enable = true,

                    -- NOTE: these are the names of the parsers and not the filetype. (for example if you want to
                    -- disable highlighting for the `tex` filetype, you need to include `latex` in this list as this is
                    -- the name of the parser)
                    -- list of language that will be disabled
                    -- disable = { "c", "rust" },

                    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
                    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
                    -- Using this option may slow down your editor, and you may see some duplicate highlights.
                    -- Instead of true it can also be a list of languages
                    additional_vim_regex_highlighting = false,
                },
            }
        end
    }
    use {
        'nvim-treesitter/nvim-treesitter-context',
        requires = 'nvim-treesitter/nvim-treesitter',
        config = function()
            require'treesitter-context'.setup{
                enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
                max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
                trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
                patterns = { -- Match patterns for TS nodes. These get wrapped to match at word boundaries.
                -- For all filetypes
                -- Note that setting an entry here replaces all other patterns for this entry.
                -- By setting the 'default' entry below, you can control which nodes you want to
                -- appear in the context window.
                default = {
                    'class',
                    'function',
                    'method',
                    -- 'for', -- These won't appear in the context
                    -- 'while',
                    -- 'if',
                    -- 'switch',
                    -- 'case',
                },
                -- Example for a specific filetype.
                -- If a pattern is missing, *open a PR* so everyone can benefit.
                --   rust = {
                    --       'impl_item',
                    --   },
                },
                exact_patterns = {
                    -- Example for a specific filetype with Lua patterns
                    -- Treat patterns.rust as a Lua pattern (i.e "^impl_item$" will
                    -- exactly match "impl_item" only)
                    -- rust = true,
                },

                -- [!] The options below are exposed but shouldn't require your attention,
                --     you can safely ignore them.

                zindex = 20, -- The Z-index of the context window
                mode = 'cursor',  -- Line used to calculate context. Choices: 'cursor', 'topline'
                separator = nil, -- Separator between context and content. Should be a single character string, like '-'.
            }
        end
    }
    use 'nvim-treesitter/nvim-treesitter-textobjects'
    -- 自動補完
    use {
        'hrsh7th/nvim-cmp',
        requires = {
            'neovim/nvim-lspconfig',
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-path',
            'hrsh7th/cmp-cmdline',
            'L3MON4D3/LuaSnip',
            'saadparwaiz1/cmp_luasnip',
            'hrsh7th/cmp-nvim-lsp-document-symbol',
            'hrsh7th/cmp-nvim-lsp-signature-help',
            'petertriho/cmp-git',
            'onsails/lspkind.nvim'
        }
    }
    use {'tzachar/cmp-tabnine', run='./install.sh', requires = 'hrsh7th/nvim-cmp'}
    use 'ray-x/cmp-treesitter'
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
                    null_ls.builtins.diagnostics.markdownlint
                },
            })
        end
    }
    -- Git
    use {
        'lewis6991/gitsigns.nvim',
        tag = 'release' -- To use the latest release
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
    -- debugger
    use 'mfussenegger/nvim-dap'

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
    -- LSPサーバー管理
    use {
        'williamboman/mason.nvim',
        requires = {
            'williamboman/mason-lspconfig.nvim',
            'neovim/nvim-lspconfig',
            'kkharji/lspsaga.nvim',
        }
    }
    -- LSP周りの設定を別ファイルで実施
    require('lsp-setup')

end)

