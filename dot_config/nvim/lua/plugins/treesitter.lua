-- treesitterとtreesitterに依存するプラグイン
local ensure_installed = {
    "lua",
    "bash",
    "java",
    "rust",
    "markdown",
    "markdown_inline",
    "http",
    "json",
    "yaml",
    "python",
    "terraform",
    "diff",
}

return {
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        build = ':TSUpdate',
        config = function()

            require("nvim-treesitter").install(ensure_installed)

            -- autocmdでファイルタイプごとにTreesitterの機能を起動する
            local group = vim.api.nvim_create_augroup('MyTreesitterSetup', { clear = true })
            vim.api.nvim_create_autocmd('FileType', {
                group = group,
                pattern = ensure_installed,
                callback = function(args)
                    -- ハイライトを有効にする
                    local ok = pcall(vim.treesitter.start, args.buf)
                    if not ok then
                        return
                    end

                    -- インデントを有効にする
                    vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                end,
            })

            -- 折り畳みを有効にする
            vim.o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
            vim.o.foldlevel = 99
            vim.o.foldmethod = "expr"
        end,
    },

    {
        "nvim-treesitter/nvim-treesitter-context",
        dependencies = "nvim-treesitter/nvim-treesitter",
        config = function()
            require("treesitter-context").setup({
                enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
                max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
                trim_scope = "outer", -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
                patterns = { -- Match patterns for TS nodes. These get wrapped to match at word boundaries.
                    -- For all filetypes
                    -- Note that setting an entry here replaces all other patterns for this entry.
                    -- By setting the 'default' entry below, you can control which nodes you want to
                    -- appear in the context window.
                    default = {
                        "class",
                        "function",
                        "method",
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
                mode = "cursor", -- Line used to calculate context. Choices: 'cursor', 'topline'
                separator = nil, -- Separator between context and content. Should be a single character string, like '-'.
            })
        end,
    },

     -- これを追加するとLSPの挙動がおかしくなったので無効化 → mainブランチへの切り替えを期に再度有効化
    {
        'nvim-treesitter/nvim-treesitter-textobjects',
        branch = "main",
    },
    -- treesitter unitをテキストオブジェクトに追加
    "David-Kunz/treesitter-unit",
}
