local map = require('common').map
local buf_map = require('common').buf_map

-- UI変更に関連する全般
return {
    {
        'folke/tokyonight.nvim',
        lazy = false,
        priority = 1000,
        config = function()
            require("tokyonight").setup({
                style = "night",
                styles = {
                    functions = {}
                },
                sidebars = { "qf", "vista_kind", "terminal", "packer", "fern", "sagaoutline", "aerial" },
            })

            -- require('plugins.heirline').setup()

            vim.cmd.colorscheme("tokyonight")
        end
    },

    -- 起動時の画面をカスタマイズする
    {
        'goolord/alpha-nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        config = function()
            require('alpha').setup(require'alpha.themes.startify'.config)
        end
    },

    -- 検索結果をわかりやすくする
    {
        'kevinhwang91/nvim-hlslens',
        config = function()
            require('hlslens').setup()
        end
    },

    -- スクロールバーを表示する
    {
        'petertriho/nvim-scrollbar',
        config = function()
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
        end
    },

    -- Gitの変更箇所を表示する
    {
        'lewis6991/gitsigns.nvim',
        version = 'v0.7', -- To the latest release
        config = function()
            require('gitsigns').setup()
        end
    },

    -- nvimの標準をファイラーを置き換え
    'lambdalisue/fern-hijack.vim',

    -- ファイラー
    {
        'lambdalisue/fern.vim',
        dependencies = {
            -- 'antoinemadec/FixCursorHold.nvim',
            'lambdalisue/nerdfont.vim',
            'lambdalisue/fern-git-status.vim',
            'lambdalisue/fern-hijack.vim',
        },
        config = function()
            vim.g['fern#default_hidden'] = 1
        end
    },

    -- fernでGitのステータスを表示
    'lambdalisue/fern-git-status.vim',

    -- fernでnerdfontを表示する
    {
        'lambdalisue/fern-renderer-nerdfont.vim',
        dependencies = {
            'lambdalisue/fern.vim'
        },
        config = function ()
            vim.g['fern#renderer'] = 'nerdfont'
        end
    },

    -- fernでファイルにカーソルがあたった際に自動でプレビューする
    {
        'yuki-yano/fern-preview.vim',
        dependencies = {
            'lambdalisue/fern.vim'
        },
        config = function ()
            vim.g['fern_auto_preview'] = false
        end
    },

    -- ターミナルの表示
    -- Lspsagaにも同様の機能があるが、こちらのほうが挙動が良い
    {
        "akinsho/toggleterm.nvim",
        version = '*',
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
    },

    -- lazygitをカレントファイルに対して実行する
    -- toggleterm.nvimだと工夫が必要なのでこちらで実行する
    {
        "kdheepak/lazygit.nvim",
        -- optional for floating window border decoration
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        config = function()
            map("n", "<A-g>", "<cmd>LazyGitCurrentFile<cr>", {})
        end
    },

    -- アウトライン
    {
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

                on_attach = function(bufnr)
                    -- Jump forwards/backwards with '{' and '}'
                    -- Jump up the tree with '[' or ']'
                    local wk = require("which-key")
                    wk.register({
                        ["{"] = { "<cmd>AerialNext<CR>", "Next element"},
                        ["}"] = { "<cmd>AerialPrev<CR>", "Prev element"},
                        -- ["["] = { "<cmd>lua require('aerial').next_up()<CR>", "Next up element"},
                        -- ["]"] = { "<cmd>lua require('aerial').prev_up()<CR>", "Prev up element"},
                    }, {
                        mode = "n",
                        buffer = bufnr
                    })
                end
            })

            map('n', '(', '<cmd>AerialToggle!<CR>', {})
            map('n', ')', '<cmd>AerialNavToggle<CR>', {})

        end
    },

    {
        'NvChad/nvim-colorizer.lua',
        config = function ()
            require('colorizer').setup()
        end
    },

    -- LSP用の色定義を追加
    'folke/lsp-colors.nvim',

    {
        "shellRaining/hlchunk.nvim",
        event = { "UIEnter" },
        config = function()
            support_filetypes = {
                "*.sh",
                "*.ts",
                "*.tsx",
                "*.js",
                "*.jsx",
                "*.html",
                "*.json",
                "*.go",
                "*.c",
                "*.py",
                "*.cpp",
                "*.rs",
                "*.h",
                "*.hpp",
                "*.lua",
                "*.vue",
                "*.java",
                "*.cs",
                "*.dart",
                "*.yml"
            }

            require("hlchunk").setup({
                chunk = {
                    enable = true,
                    notify = false,
                    use_treesitter = true,
                    -- details about support_filetypes and exclude_filetypes in https://github.com/shellRaining/hlchunk.nvim/blob/main/lua/hlchunk/utils/filetype.lua
                    support_filetypes = support_filetypes,
                },
                blank = {
                    enable = false,
                },
            })
        end
    },

    -- {
    --     'lukas-reineke/indent-blankline.nvim',
    --     dependencies = {
    --         'nvim-treesitter/nvim-treesitter'
    --     },
    --     config = function()
    --         require('ibl').setup()
    --     end
    -- },

    {
        'b0o/incline.nvim',
        config = function()
            local helpers = require 'incline.helpers'
            local devicons = require 'nvim-web-devicons'
            require('incline').setup {
                window = {
                    padding = 0,
                    margin = { horizontal = 0 },
                },
                render = function(props)
                    local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ':t')
                    if filename == '' then
                        filename = '[No Name]'
                    end
                    local ft_icon, ft_color = devicons.get_icon_color(filename)
                    local modified = vim.bo[props.buf].modified
                    return {
                        ft_icon and { ' ', ft_icon, ' ', guibg = ft_color, guifg = helpers.contrast_color(ft_color) } or '',
                        ' ',
                        { filename, gui = modified and 'bold,italic' or 'bold' },
                        ' ',
                        guibg = '#44406e',
                    }
                end,
            }
        end,
        -- Optional: Lazy load Incline
        event = 'VeryLazy',
    },
}
