return {
    -- 自動補完
    {
        'hrsh7th/nvim-cmp',
        dependencies = {
            'neovim/nvim-lspconfig',
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-path',
            'hrsh7th/cmp-cmdline',
            'L3MON4D3/LuaSnip',
            'saadparwaiz1/cmp_luasnip',
            -- 'hrsh7th/cmp-vsnip',
            -- 'hrsh7th/vim-vsnip',
            'ray-x/cmp-treesitter',
            -- 'hrsh7th/cmp-nvim-lsp-document-symbol', -- lsp_signagureと役割が重複するのでコメントアウト
            -- 'hrsh7th/cmp-nvim-lsp-signature-help', -- lsp_signagureと役割が重複するのでコメントアウト
            'petertriho/cmp-git',
            'onsails/lspkind.nvim',
            {
                "zbirenbaum/copilot-cmp",
                config = function()
                    require("copilot_cmp").setup()
                end
            }
        },
        config = function()
            -- nvim-cmpの設定
            local cmp = require("cmp")
            local lspkind = require('lspkind')
            local cmp_autopairs = require('nvim-autopairs.completion.cmp')

            cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())

            local source_mapping = {
                buffer = "[Buf]",
                copilot = "[AI]",
                nvim_lsp = "[LSP]",
                -- vsnip = "[Snip]",
                luasnip = "[Snip]",
                treesitter = "[TS]",
                -- cmp_tabnine = "[TAB]",
                path = "[Path]",
            }

            local has_words_before = function()
                local line, col = table.unpack(vim.api.nvim_win_get_cursor(0))
                return col ~= 0 and
                    vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
            end

            cmp.setup({
                snippet = {
                    expand = function(args)
                        -- vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
                        require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
                    end,
                },
                window = {
                    completion = cmp.config.window.bordered(),
                    documentation = cmp.config.window.bordered(),
                },
                mapping = cmp.mapping.preset.insert({
                    ['<C-p>'] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
                    ['<C-n>'] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
                    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
                    ['<C-f>'] = cmp.mapping.scroll_docs(4),
                    ['<C-Space>'] = cmp.mapping.complete(),
                    ['<C-e>'] = cmp.mapping.close(),
                    ["<CR>"] = cmp.mapping({
                        i = function(fallback)
                            if cmp.visible() and cmp.get_active_entry() then
                                cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false })
                            else
                                fallback()
                            end
                        end,
                        s = cmp.mapping.confirm({ select = true }),
                        c = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false }),
                    }),

                    ["<C-j>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
                        elseif require('luasnip').expandable() then
                            require('luasnip').expand()
                        elseif require('luasnip').jumpable(1) then
                            require('luasnip').jump(1)
                            -- elseif vim.fn["vsnip#available"](1) == 1 then
                            --     feedkey("<Plug>(vsnip-expand-or-jump)", "")
                        elseif has_words_before() then
                            cmp.complete()
                        else
                            fallback() -- The fallback function sends a already mapped key. In this case, it's probably `<Tab>`.
                        end
                    end, { "i", "s" }),

                    ["<C-k>"] = cmp.mapping(function()
                        if cmp.visible() then
                            cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
                        elseif require('luasnip').jumpable(-1) then
                            require('luasnip').jump(-1)
                            -- elseif vim.fn["vsnip#jumpable"](-1) == 1 then
                            --     feedkey("<Plug>(vsnip-jump-prev)", "")
                        end
                    end, { "i", "s" }),

                    ["<Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
                        elseif require('luasnip').expandable() then
                            require('luasnip').expand()
                        elseif require('luasnip').jumpable(1) then
                            require('luasnip').jump(1)
                            -- elseif vim.fn["vsnip#available"](1) == 1 then
                            --     feedkey("<Plug>(vsnip-expand-or-jump)", "")
                        elseif has_words_before() then
                            cmp.complete()
                        else
                            fallback() -- The fallback function sends a already mapped key. In this case, it's probably `<Tab>`.
                        end
                    end, { "i", "s" }),

                    ["<S-Tab>"] = cmp.mapping(function()
                        if cmp.visible() then
                            cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
                        elseif require('luasnip').jumpable(-1) then
                            require('luasnip').jump(-1)
                        end
                    end, { "i", "s" }),
                }),

                sources = cmp.config.sources({
                    { name = 'nvim_lsp', group_index = 2 },
                    { name = 'copilot', group_index = 2 },
                    -- { name = 'vsnip' }, -- For vsnip users.
                    { name = 'luasnip', group_index = 2 }, -- For luasnip users.
                    -- { name = 'cmp_tabnine' },
                    { name = 'treesitter' },
                    -- { name = 'nvim_lsp_signature_help' },
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

            -- buffer source for `/` (if you enabled `native_menu`, this won't work anymore).
            cmp.setup.cmdline('/', {
                mapping = cmp.mapping.preset.cmdline(),
                sources = {
                    { name = 'nvim_lsp_document_symbol' }
                },
                {
                    { name = 'buffer' }
                }
            })

            -- cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
            cmp.setup.cmdline(':', {
                mapping = cmp.mapping.preset.cmdline(),
                sources = cmp.config.sources({
                    { name = 'path' }
                }, {
                    {
                        name = 'cmdline',
                        option = {
                            ignore_cmds = { 'Man', '!' }
                        }
                    }
                })
            })

            require("luasnip.loaders.from_vscode").lazy_load()
        end
    },
}
