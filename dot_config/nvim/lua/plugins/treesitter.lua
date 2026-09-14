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
    "go",
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
        dependencies = "nvim-treesitter/nvim-treesitter",
        config = function()
            require("nvim-treesitter-textobjects").setup({
                select = { lookahead = true },
                move = { set_jumps = true },
            })

            -- Keep targets.vim's aa/ia and Vim's ap/ip text objects intact.
            for _, mapping in ipairs({
                { "af", "@function.outer", "Around function" },
                { "if", "@function.inner", "Inside function" },
                { "ac", "@class.outer", "Around class" },
                { "ic", "@class.inner", "Inside class" },
                { "aP", "@parameter.outer", "Around parameter" },
                { "iP", "@parameter.inner", "Inside parameter" },
            }) do
                vim.keymap.set({ "x", "o" }, mapping[1], function()
                    require("nvim-treesitter-textobjects.select").select_textobject(mapping[2], "textobjects")
                end, { desc = mapping[3] })
            end

            -- r = routine; preserve ftplugin [m/]m and Vim's [f/]f file jumps.
            for _, mapping in ipairs({
                { "]r", "goto_next_start", "Next function start" },
                { "[r", "goto_previous_start", "Previous function start" },
                { "]R", "goto_next_end", "Next function end" },
                { "[R", "goto_previous_end", "Previous function end" },
            }) do
                vim.keymap.set({ "n", "x", "o" }, mapping[1], function()
                    require("nvim-treesitter-textobjects.move")[mapping[2]]("@function.outer", "textobjects")
                end, { desc = mapping[3] })
            end

            vim.keymap.set("n", "<leader>>", function()
                require("nvim-treesitter-textobjects.swap").swap_next("@parameter.inner")
            end, { desc = "Swap parameter with next" })
            vim.keymap.set("n", "<leader><", function()
                require("nvim-treesitter-textobjects.swap").swap_previous("@parameter.inner")
            end, { desc = "Swap parameter with previous" })
        end,
    },
    -- treesitter unitをテキストオブジェクトに追加
    "David-Kunz/treesitter-unit",
}
