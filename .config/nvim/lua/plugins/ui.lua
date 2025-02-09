local map = require('common').map

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
            vim.cmd.highlight({ "BlinkCmpMenu", "guibg=#202a42"})
            vim.cmd.highlight({ "BlinkCmpMenuSelection", "guibg=#324268"})
            vim.cmd.highlight({ "BlinkCmpDoc", "guibg=#202a42"})
            vim.cmd.highlight({ "BlinkCmpDocBorder", "guibg=#202a42"})
            vim.cmd.highlight({ "BlinkCmpDocSeparator", "guibg=#202a42"})
            vim.cmd.highlight({ "BlinkCmpSignatureHelp", "guibg=#202a42"})
            vim.cmd.highlight({ "BlinkCmpSignatureHelpBorder", "guibg=#202a42"})
            vim.cmd.highlight({ "BlinkCmpSignatureHelpActiveParameter", "guibg=#324268"})
        end
    },

    -- 起動時の画面をカスタマイズする
    {
        'goolord/alpha-nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        config = function()
            require('alpha').setup(require 'alpha.themes.startify'.config)
        end
    },

    -- 検索結果をわかりやすくする
    {
        'kevinhwang91/nvim-hlslens',
        config = function()
            require('hlslens').setup()
        end
    },

    -- Gitの変更箇所を表示する
    {
        'lewis6991/gitsigns.nvim',
        version = 'v0.7', -- To the latest release
        config = function()
            require('gitsigns').setup({
                current_line_blame_opts = {
                    virt_text = true,
                    virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
                    delay = 500,
                    ignore_whitespace = false,
                    virt_text_priority = 100,
                },
            })
        end
    },

    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
            "MunifTanjim/nui.nvim",
            -- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
        },
        config = function()
            require('neo-tree').setup({
                source_selector = {
                    statusline = true, -- toggle to show selector on statusline
                    show_scrolled_off_parent_node = false,                    -- boolean
                    sources = {                                               -- table
                        {
                            source = "filesystem",                                -- string
                            display_name = " 󰉓 Files "                            -- string | nil
                        },
                        {
                            source = "buffers",                                   -- string
                            display_name = " 󰈚 Buffers "                          -- string | nil
                        },
                    },
                },
                close_if_last_window = true, -- Close Neo-tree if it is the last window left in the tab
                popup_border_style = "rounded",
                enable_git_status = true,
                enable_diagnostics = true,
                open_files_do_not_replace_types = { "terminal", "trouble", "qf", "sagafinder" }, -- when opening files, do not use windows containing these filetypes or buftypes
                filesystem = {
                    filtered_items = {
                        visible = false, -- when true, they will just be displayed differently than normal items
                        hide_dotfiles = false,
                        hide_gitignored = false,
                        hide_hidden = true, -- only works on Windows for hidden files/directories
                        hide_by_name = {
                          ".git"
                        },
                        hide_by_pattern = { -- uses glob style patterns
                          --"*.meta",
                          --"*/src/*/tsconfig.json",
                        },
                    },
                    follow_current_file = {
                        enabled = true,
                        leave_dirs_open = false
                    }
                },
                window = {
                    mappings = {
                        ["P"] = { "toggle_preview", config = { use_float = true, use_image_nvim = false } },
                        ["<Esc>"] = { "close_window", config = { use_float = true, use_image_nvim = false } },
                    }
                },
                buffers = {
                    window = {
                        mappings = {
                            ["d"] = "buffer_delete",
                        }
                    },
                },
            })
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
                    wk.add({
                        mode = { "n" },
                        buffer = bufnr,
                        -- { "{", "<cmd>AerialNext<CR>", desc = "Next element" },
                        -- { "}", "<cmd>AerialPrev<CR>", desc = "Prev element" },
                        -- ["["] = { "<cmd>lua require('aerial').next_up()<CR>", "Next up element"},
                        -- ["]"] = { "<cmd>lua require('aerial').prev_up()<CR>", "Prev up element"},
                    })
                end
            })

            map('n', '(', '<cmd>AerialToggle!<CR>', {})
            -- map('n', ')', '<cmd>AerialNavToggle<CR>', {})
        end
    },

    {
        'NvChad/nvim-colorizer.lua',
        config = function()
            require('colorizer').setup()
        end
    },

    {
        "shellRaining/hlchunk.nvim",
        event = { "UIEnter" },
        config = function()
            local support_filetypes = {
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
                "*.yml",
                "*.tf"
            }

            require("hlchunk").setup({
                chunk = {
                    enable = true,
                    notify = false,
                    delay = 0,
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
                        ft_icon and { ' ', ft_icon, ' ', guibg = ft_color, guifg = helpers.contrast_color(ft_color) } or
                        '',
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
