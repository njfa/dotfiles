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
            local conditions = require("heirline.conditions")
            local utils = require("heirline.utils")
            local colors = require("tokyonight.colors").setup()

            local Separator = {
                provider  = function()
                    return "%="
                end,
            }

            local ViMode = {
                -- get vim current mode, this information will be required by the provider
                -- and the highlight functions, so we compute it only once per component
                -- evaluation and store it as a component attribute
                init = function(self)
                    self.mode = vim.fn.mode(1) -- :h mode()
                end,
                -- Now we define some dictionaries to map the output of mode() to the
                -- corresponding string and color. We can put these into `static` to compute
                -- them at initialisation time.
                static = {
                    mode_names = { -- change the strings if you like it vvvvverbose!
                        n = "NORMAL",
                        no = "NORMAL?",
                        nov = "NORMAL?",
                        noV = "NORMAL?",
                        ["no\22"] = "NORMAL?",
                        niI = "NORMALi",
                        niR = "NORMALr",
                        niV = "NORMALv",
                        nt = "NORMALt",
                        v = "VISUAL",
                        vs = "VISUALs",
                        V = "VISUAL LINE",
                        Vs = "lISUALs",
                        ["\22"] = "VISUAL BLOCK",
                        ["\22s"] = "VISUAL BLOCK",
                        s = "S",
                        S = "S_",
                        ["\19"] = "^S",
                        i = "INSERT",
                        ic = "INSERTc",
                        ix = "INSERTx",
                        R = "R",
                        Rc = "Rc",
                        Rx = "Rx",
                        Rv = "Rv",
                        Rvc = "Rv",
                        Rvx = "Rv",
                        c = "COMMAND",
                        cv = "Ex",
                        r = "...",
                        rm = "M",
                        ["r?"] = "?",
                        ["!"] = "!",
                        t = "TERMINAL",
                    },
                    mode_colors = {
                        n = "blue" ,
                        i = "green2",
                        v = "yellow",
                        V =  "orange",
                        ["\22"] =  "red",
                        c =  "purple",
                        s =  "purple",
                        S =  "purple",
                        ["\19"] =  "purple",
                        R =  "red1",
                        r =  "red1",
                        ["!"] =  "red1",
                        t =  "blue2",
                    },
                },

                update = {
                    "ModeChanged",
                    pattern = "*:*",
                    callback = vim.schedule_wrap(function()
                        vim.cmd("redrawstatus")
                    end),
                },

                {
                    -- We can now access the value of mode() that, by now, would have been
                    -- computed by `init()` and use it to index our strings dictionary.
                    -- note how `static` fields become just regular attributes once the
                    -- component is instantiated.
                    -- To be extra meticulous, we can also add some vim statusline syntax to
                    -- control the padding and make sure our string is always at least 2
                    -- characters long. Plus a nice Icon.
                    provider = function(self)
                        return " %2("..self.mode_names[self.mode].."%) "
                    end,
                    -- Same goes for the highlight. Now the foreground will change according to the current mode.
                    hl = function(self)
                        local mode = self.mode:sub(1, 1) -- get only the first mode character
                        return {
                            fg = "black",
                            bg = self.mode_colors[mode],
                            bold = true,
                        }
                    end,
                    -- Re-evaluate the component only on ModeChanged event!
                    -- Also allows the statusline to be re-evaluated when entering operator-pending mode
                },
                {
                    provider = function()
                        return ""
                    end,
                    -- Same goes for the highlight. Now the foreground will change according to the current mode.
                    hl = function(self)
                        local mode = self.mode:sub(1, 1) -- get only the first mode character
                        return {
                            fg = self.mode_colors[mode],
                            bg = "bg",
                            bold = true,
                        }
                    end,
                }
            }

            local FileNameBlock = {
                -- let's first set up some attributes needed by this component and it's children
                init = function(self)
                    self.filename = vim.api.nvim_buf_get_name(0)
                end,
            }
            -- We can now define some children separately and add them later

            local WorkDir = {
                provider = function()
                    local cwd = vim.fn.getcwd(0)
                    cwd = vim.fn.fnamemodify(cwd, ":~")
                    if not conditions.width_percent_below(#cwd, 0.25) then
                        cwd = vim.fn.pathshorten(cwd)
                    end
                    local trail = cwd:sub(-1) == '/' and '' or "/"
                    return  "  " .. cwd  .. trail
                end,
                hl = { fg = "gray", bg = "bg_dark", bold = true },
            }

            local FileName = {
                provider = function(self)
                    -- first, trim the pattern relative to the current directory. For other
                    -- options, see :h filename-modifers
                    local filename = vim.fn.fnamemodify(self.filename, ":.")
                    if filename == "" then return "[New Buffer]" end
                    -- now, if the filename would occupy more than 1/4th of the available
                    -- space, we trim the file path to its initials
                    -- See Flexible Components section below for dynamic truncation
                    if not conditions.width_percent_below(#filename, 0.25) then
                        filename = vim.fn.pathshorten(filename)
                    end
                    return filename
                end,
                hl = { fg = "fg", bg = "bg_dark" },
            }

            local FileFlags = {
                {
                    condition = function()
                        return vim.bo.modified
                    end,
                    provider = " ●",
                    hl = { fg = "green", bg = "bg_dark" },
                },
                {
                    condition = function()
                        return not vim.bo.modifiable or vim.bo.readonly
                    end,
                    provider = " ",
                    hl = { fg = "red", bg = "bg_dark" },
                },
            }

            -- Now, let's say that we want the filename color to change if the buffer is
            -- modified. Of course, we could do that directly using the FileName.hl field,
            -- but we'll see how easy it is to alter existing components using a "modifier"
            -- component

            local FileNameModifer = {
                hl = function()
                    if vim.bo.modified then
                        -- use `force` because we need to override the child's hl foreground
                        return { fg = "fg", bg = "bg_dark", bold = true, force=true }
                    end
                end,
            }

            -- let's add the children to our FileNameBlock component
            FileNameBlock = utils.insert(
            FileNameBlock,
            utils.insert(FileNameModifer, FileName), -- a new table where FileName is a child of FileNameModifier
            FileFlags,
            { provider = '%<'} -- this means that the statusline is cut here when there's not enough space
            )

            local FileType = {
                provider = function()
                    return "  " .. string.upper(vim.bo.filetype)
                end,
                hl = { fg = "black", bg = "teal", bold = true },
            }

            local FileEncoding = {
                {
                    provider = function()
                        return ""
                    end,
                    hl = { fg = "teal", bg = "bg", bold = true },
                },
                {
                    provider = function()
                        local enc = (vim.bo.fenc ~= '' and vim.bo.fenc) or vim.o.enc -- :h 'enc'
                        return " " .. enc:upper()
                    end,
                    hl = { fg = "black", bg = "teal", bold = true },
                }
            }

            local FileFormat = {
                provider = function()
                    local fmt = vim.bo.fileformat
                    return "  " .. fmt:upper() .. " "
                end,
                hl = { fg = "black", bg = "teal", bold = true },
            }

            local FileSize = {
                provider = function()
                    -- stackoverflow, compute human readable file size
                    local suffix = { 'B', 'k', 'M', 'G', 'T', 'P', 'E' }
                    local fsize = vim.fn.getfsize(vim.api.nvim_buf_get_name(0))
                    fsize = (fsize < 0 and 0) or fsize
                    if fsize < 1024 then
                        return " (" .. fsize..suffix[1] .. ") "
                    end
                    local i = math.floor((math.log(fsize) / math.log(1024)))
                    return " (" .. string.format("%.2g%s", fsize / math.pow(1024, i), suffix[i + 1]) .. ") "
                end,
                hl = { fg = "fg", bg = "bg_dark" },
            }

            -- We're getting minimalists here!
            local Ruler = {
                -- %l = current line number
                -- %L = number of lines in the buffer
                -- %c = column number
                -- %P = percentage through file of displayed window
                provider = "ROW:%7(%l/%3L%) (%P)  COL:%2c ",
            }

            local LSPActive = {
                condition = conditions.lsp_attached,
                update = {'LspAttach', 'LspDetach'},

                -- You can keep it simple,
                -- provider = " [LSP]",

                -- Or complicate things a bit and get the servers names
                provider  = function()
                    local names = {}
                    for i, server in pairs(vim.lsp.get_active_clients({ bufnr = 0 })) do
                        table.insert(names, server.name)
                    end
                    return "  LSP:[" .. table.concat(names, ", ") .. "] "
                end,
                hl = { fg = "orange", bg = "bg_dark", bold = true },
            }
            local Git = {
                condition = conditions.is_git_repo,

                init = function(self)
                    self.status_dict = vim.b.gitsigns_status_dict
                    self.has_changes = self.status_dict.added ~= 0 or self.status_dict.removed ~= 0 or self.status_dict.changed ~= 0
                end,

                hl = { fg = "fg", bg = "bg_dark" },


                {   -- git branch name
                    provider = function(self)
                        return "   " .. self.status_dict.head
                    end,
                    hl = { bold = true }
                },
                -- You could handle delimiters, icons and counts similar to Diagnostics
                {
                    condition = function(self)
                        return self.has_changes
                    end,
                    provider = " ("
                },
                {
                    provider = function(self)
                        local count = self.status_dict.added or 0
                        return count > 0 and ("+" .. count)
                    end,
                    hl = { fg = "teal" },
                },
                {
                    provider = function(self)
                        local count = self.status_dict.removed or 0
                        return count > 0 and ("-" .. count)
                    end,
                    hl = { fg = "red" },
                },
                {
                    provider = function(self)
                        local count = self.status_dict.changed or 0
                        return count > 0 and ("~" .. count)
                    end,
                    hl = { fg = "orange" },
                },
                {
                    condition = function(self)
                        return self.has_changes
                    end,
                    provider = ") ",
                },
                {
                    provider = function()
                        return " "
                    end,
                    hl = { fg = "fg", bold = false },
                }
            }

            local DAPMessages = {
                condition = function()
                    local session = require("dap").session()
                    return session ~= nil
                end,
                provider = function()
                    return " " .. require("dap").status()
                end,
                hl = "Debug"
                -- see Click-it! section for clickable actions
            }
            local StatusLine = {
                {
                    ViMode,
                    Git,
                    WorkDir,
                    FileNameBlock,
                    FileSize,
                },
                {
                    Separator,
                    LSPActive,
                    DAPMessages,
                },
                {
                    Separator,
                    Ruler,
                    FileEncoding,
                    FileType,
                    FileFormat,
                },
            }

            require("heirline").setup({
                statusline = StatusLine,
                opts = {
                    colors = require("tokyonight.colors").setup(),
                },
            })
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
                    numbers = "buffer_id",
                    buffer_close_icon = '',
                    max_name_length = 100,
                    max_prefix_length = 15, -- prefix used when a buffer is de-duplicated
                    truncate_names = true, -- whether or not tab names should be truncated
                    tab_size = 0,
                    indicator = {
                        icon = '▎', -- this should be omitted if indicator style is not 'icon'
                        -- style = 'underline'
                    },
                    diagnostics = "nvim_lsp",
                    diagnostics_indicator = function(count, level, diagnostics_dict, context)
                        local s = " "
                        for e, n in pairs(diagnostics_dict) do
                            local sym = e == "error" and ""
                            or (e == "warning" and "" or e == "info" and "" or "" )
                            s = s .. sym .. n .. ' '
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
                    },
                    -- sort_by = 'insert_after_current'
                }
            }
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
    use {
        'haringsrob/nvim_context_vt',
        requires = 'nvim-treesitter/nvim-treesitter',
        setup = function()
            require("nvim-treesitter.parsers")
        end,
        config = function()
            require('nvim_context_vt').setup({
                -- disable_ft = {'yml', 'py'},
                disable_virtual_lines = true,
            })
        end
    }
    -- キーバインドをわかりやすくする
    use {
        "folke/which-key.nvim",
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
    -- debugger
    use 'mfussenegger/nvim-dap'
    -- use {
    --     "rcarriga/nvim-dap-ui", requires = {"mfussenegger/nvim-dap"},
    --     config = function()
    --         require("dapui").setup()
    --     end
    -- }
    -- use {
    --     "folke/neodev.nvim",
    --     config = function()
    --         require("neodev").setup({
    --             library = { plugins = { "nvim-dap-ui" }, types = true },
    --         })
    --     end
    -- }


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
    use {
        "ray-x/lsp_signature.nvim",
        config = function()
            local cfg = {
                hint_prefix = " ",
                floating_window_off_x = 5, -- adjust float windows x position.
                floating_window_off_y = function() -- adjust float windows y position. e.g. set to -2 can make floating window move up 2 lines
                    local linenr = vim.api.nvim_win_get_cursor(0)[1] -- buf line number
                    local pumheight = vim.o.pumheight
                    local winline = vim.fn.winline() -- line number in the window
                    local winheight = vim.fn.winheight(0)

                    -- window top
                    if winline - 1 < pumheight then
                        return pumheight
                    end

                    -- window bottom
                    if winheight - winline < pumheight then
                        return -pumheight
                    end
                    return 0
                end,
            }
            require("lsp_signature").setup(cfg)
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
        setup = function() vim.g.mkdp_filetypes = { "markdown", "plantuml" } end,
        ft = { "markdown", "plantuml" },
    }

    -- HTML入力時の補助
    use {
        "windwp/nvim-ts-autotag",
        config = function()
            require("nvim-ts-autotag").setup()
        end
    }

    if packer_bootstrap then
        require('packer').sync()
    end
end)

