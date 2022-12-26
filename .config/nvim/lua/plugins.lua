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
        cond = function() return vim.fn.exists('g:vscode') == 0 end,
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
        requires = "neovim/nvim-lspconfig"
    }
    -- ステータスラインをリッチな見た目にする
    use {
        'nvim-lualine/lualine.nvim',
        requires = {
            'folke/tokyonight.nvim',
            -- ステータスラインに関数名を表示する
            'SmiteshP/nvim-navic',
            'kyazdani42/nvim-web-devicons'
        },
        cond = function() return vim.fn.exists('g:vscode') == 0 end,
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
        tag = "v3.*",
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
                    tab_selected = {
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
                    end,
                    offsets = {
                        {
                            filetype = "fern",
                            text = function()
                                return vim.fn.getcwd()
                            end,
                            highlight = "Directory",
                            text_align = "left"
                        }
                    }
                }
            }
        end
    }
    -- サイドバーを表示する
    -- use {
    --     "sidebar-nvim/sidebar.nvim",
    --     branch = 'dev', -- optional but strongly recommended
    --     config = function()
    --         require('sidebar-nvim').setup({
    --             bindings = {
    --                 ['q'] = function()
    --                     require('sidebar-nvim').close()
    --                 end,
    --                 ['<Esc>'] = function()
    --                     require('sidebar-nvim').close()
    --                 end
    --             },
    --             open = false,
    --             initial_width = 30,
    --             hide_statusline = true,
    --             section_separator = '',
    --             sections = {'buffers', 'git', 'todos'},
    --             todos = {
    --                 icon = "",
    --                 ignored_paths = {'~'}, -- ignore certain paths, this will prevent huge folders like $HOME to hog Neovim with TODO searching
    --                 initially_closed = true, -- whether the groups should be initially closed on start. You can manually open/close groups later.
    --             },
    --             buffers = {
    --                 icon = "",
    --                 ignored_buffers = {}, -- ignore buffers by regex
    --                 sorting = "id", -- alternatively set it to "name" to sort by buffer name instead of buf id
    --                 show_numbers = true, -- whether to also show the buffer numbers
    --                 ignore_not_loaded = true, -- whether to ignore not loaded buffers
    --                 ignore_terminal = true, -- whether to show terminal buffers in the list
    --             }
    --         })
    --     end
    -- }
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
    use {
        'haringsrob/nvim_context_vt',
        requires = 'nvim-treesitter/nvim-treesitter',
        cond = function() return vim.fn.exists('g:vscode') == 0 end,
        setup = function()
            require("nvim-treesitter.parsers")
            -- require('nvim_context_vt').setup()
        end
    }
    -- キーバインドをわかりやすくする
    use {
        "folke/which-key.nvim",
        cond = function() return vim.fn.exists('g:vscode') == 0 end,
        config = function()
            -- which-key.nvimの表示間隔を狭める
            vim.opt.timeoutlen = 200
            local wk = require("which-key")
            wk.register({
                ["<leader>"] = {
                    a = { name = "Toggle aerial" },
                    b = { name = "[T] buffers" },
                    g = { name = "[T] live_grep" },
                    f = { name = "[T] find_files" },
                    w = { name = "Save buffer" },
                    u = { name = "Toggle undotree" },
                    c = { name = "New buffer" },
                    C = { name = "New tab" },
                    d = { name = "Close buffer" },
                    D = { name = "Close tab" },
                    p = { name = "Open Trouble" },
                    q = { name = "Close window" },
                    Q = { name = "Close all window" },
                    r = { name = "[T] frecency" },
                    s = { name = "Toggle sidebar" },
                    ["/"] = { name = "[T] search current buffer" },
                    [":"] = { name = "[T] command history" },
                },
                ["g"] = {
                    ["<Tab>"] = { name = "Lspsaga code_action" },
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

            function term_toggle()
                floatterm:toggle()
            end
            map("n", "<A-d>", "<cmd>lua term_toggle()<cr>", {})
            map("t", "<A-d>", "<cmd>lua term_toggle()<cr>", {})

            if vim.fn.executable('lazygit') == 1 then
                local lazygit = Terminal:new({
                    cmd = "lazygit",
                    dir = ".",
                    autochdir = true,
                    direction = "float",
                    hidden = true
                })

                function lazygit_toggle()
                    lazygit:toggle()
                end
                map("n", "<A-g>", "<cmd>lua lazygit_toggle()<cr>", {})
                map("t", "<A-g>", "<cmd>lua lazygit_toggle()<cr>", {})
            end
        end
    }
    -- ファジーファインダー
    use {
        'nvim-telescope/telescope.nvim', branch = 'master',
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
        cond = function() return vim.fn.exists('g:vscode') == 0 end,
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
        cond = function() return vim.fn.exists('g:vscode') == 0 end,
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
        cond = function() return vim.fn.exists('g:vscode') == 0 end,
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
    -- treesitter
    use {
        'nvim-treesitter/nvim-treesitter',
        run = function()
            local ts_update = require('nvim-treesitter.install').update({ with_sync = true })
            ts_update()
        end,
        config = function()
            require('nvim-treesitter.configs').setup {
                -- A list of parser names, or "all"
                ensure_installed = { "lua", "rust" },

                -- Install parsers synchronously (only applied to `ensure_installed`)
                sync_install = false,

                -- Automatically install missing parsers when entering buffer
                auto_install = true,

                -- List of parsers to ignore installing (for "all")
                ignore_install = { "gitignore" },

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
                    disable = { "vim", "help" },

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
            require('treesitter-context').setup{
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
    -- use 'nvim-treesitter/nvim-treesitter-textobjects' -- これを追加するとLSPの挙動がおかしくなったので無効化
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
        },
        config = function()
            -- nvim-cmpの設定
            local cmp = require("cmp")
            local lspkind = require('lspkind')
            local source_mapping = {
                buffer = "[Buf]",
                nvim_lsp = "[LSP]",
                luasnip = "[Snip]",
                treesitter = "[TS]",
                cmp_tabnine = "[TN]",
                path = "[Path]",
            }

            local has_words_before = function()
                if vim.api.nvim_buf_get_option(0, "buftype") == "prompt" then return false end
                local line, col = unpack(vim.api.nvim_win_get_cursor(0))
                return col ~= 0 and vim.api.nvim_buf_get_text(0, line-1, 0, line-1, col, {})[1]:match("^%s*$") == nil
            end

            cmp.setup({
                snippet = {
                    -- REQUIRED - you must specify a snippet engine
                    expand = function(args)
                        require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
                    end,
                },
                window = {
                    -- completion = cmp.config.window.bordered(),
                    -- documentation = cmp.config.window.bordered(),
                },
                mapping = cmp.mapping.preset.insert({
                    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
                    ['<C-f>'] = cmp.mapping.scroll_docs(4),
                    ['<C-Space>'] = cmp.mapping.complete(),
                    ['<C-e>'] = cmp.mapping.abort(),
                    ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
                    ['<Tab>'] = vim.schedule_wrap(function(fallback)
                        if cmp.visible() and has_words_before() then
                            cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
                        else
                            fallback()
                        end
                    end),
                }),
                sources = cmp.config.sources({
                    { name = 'nvim_lsp' },
                    { name = 'luasnip' }, -- For luasnip users.
                    { name = 'cmp_tabnine' },
                    { name = 'treesitter' }
                }, {
                    { name = 'buffer' },
                }),
                formatting = {
                    format = lspkind.cmp_format({
                        mode = 'symbol_text',
                        maxwidth = 50, -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)

                        before = function(entry, vim_item)
                            vim_item.kind = lspkind.presets.default[vim_item.kind]
                            local menu = source_mapping[entry.source.name]
                            if entry.source.name == "cmp_tabnine" then
                                if entry.completion_item.data ~= nil and entry.completion_item.data.detail ~= nil then
                                    menu = entry.completion_item.data.detail .. " " .. menu
                                end
                                vim_item.kind = ""
                            end
                            vim_item.menu = menu
                            return vim_item
                        end,
                    })
                },
                sorting = {
                    priority_weight = 2,
                },
            })

            -- Set configuration for specific filetype.
            cmp.setup.filetype('gitcommit', {
                sources = cmp.config.sources({
                    { name = 'cmp_git' }, -- You can specify the `cmp_git` source if you were installed it.
                }, {
                    { name = 'buffer' },
                })
            })

            -- Use buffer source for `/` (if you enabled `native_menu`, this won't work anymore).
            cmp.setup.cmdline('/', {
                mapping = cmp.mapping.preset.cmdline(),
                sources = {
                    { name = 'buffer' }
                }
            })

            -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
            cmp.setup.cmdline(':', {
                mapping = cmp.mapping.preset.cmdline(),
                sources = cmp.config.sources({
                    { name = 'path' }
                }, {
                    {
                        name = 'cmdline',
                        -- !を入力するとフリーズするので暫定的な対策を追加。
                        -- "!  "のような入力内容だと相変わらずフリーズする
                        keyword_pattern=[=[[^[:blank:]\!]*]=]
                    }
                })
            })
        end
    }
    -- treesitter unitをテキストオブジェクトに追加
    use 'David-Kunz/treesitter-unit'
    -- 色定義の追加
    use 'folke/lsp-colors.nvim'
    use {
        'tzachar/cmp-tabnine',
        run='./install.sh',
        requires = 'hrsh7th/nvim-cmp',
        config = function()
            require('cmp_tabnine.config').setup({
                max_lines = 1000,
                max_num_results = 20,
                sort = true,
                run_on_every_keystroke = true,
                snippet_placeholder = '..',
                ignored_file_types = {
                    -- default is not to ignore
                    -- uncomment to ignore in lua:
                    -- lua = true
                },
                show_prediction_strength = false
            })
        end
    }
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
                    null_ls.builtins.diagnostics.markdownlint.with({
                        extra_args = { "--disable", "MD007", "MD012" }
                    })
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
            'hrsh7th/cmp-nvim-lsp',
            'neovim/nvim-lspconfig',
            'williamboman/mason-lspconfig.nvim',
            'kkharji/lspsaga.nvim',
        },
        config = function()
            require('lspsaga').setup()

            -- mason
            require('mason').setup()
            require('mason-lspconfig').setup()
            require("mason-lspconfig").setup_handlers {
                function (server_name)
                    -- Setup lspconfig.
                    require("lspconfig")[server_name].setup {
                        on_attach = my_lsp_on_attach,
                        capabiritty = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())
                    }
                end,
            }
        end
    }

    use { 'sindrets/diffview.nvim', requires = 'nvim-lua/plenary.nvim' }

    -- 特定言語のための拡張機能
    -- Markdown入力時の補助
    use {
        'preservim/vim-markdown',
        ft = {'txt', 'markdown'},
        requires = {
            'godlygeek/tabular'
        },
        config =function ()
            vim.g.vim_markdown_folding_disabled = 1
            vim.g.vim_markdown_no_default_key_mappings = 1
            vim.g.vim_markdown_toc_autofit = 1
            vim.g.vim_markdown_new_list_item_indent = 0
        end
    }

    use {
        "iamcco/markdown-preview.nvim",
        run = "cd app && npm install",
        setup = function() vim.g.mkdp_filetypes = { "markdown" } end,
        ft = { "markdown" },
    }

    if packer_bootstrap then
        require('packer').sync()
    end
end)

