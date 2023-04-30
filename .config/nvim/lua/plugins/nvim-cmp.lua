local M = {}

function M.load()
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

return M;
