local M = {}

function M.load(use)
    -- 自動補完
    use {
        'hrsh7th/nvim-cmp',
        requires = {
            'neovim/nvim-lspconfig',
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-path',
            'hrsh7th/cmp-cmdline',
            'hrsh7th/cmp-vsnip',
            'hrsh7th/vim-vsnip',
            'ray-x/cmp-treesitter',
            'hrsh7th/cmp-nvim-lsp-document-symbol',
            'hrsh7th/cmp-nvim-lsp-signature-help',
            'petertriho/cmp-git',
            'onsails/lspkind.nvim'
        },
        config = function()
            -- nvim-cmpの設定
            local cmp = require("cmp")
            local lspkind = require('lspkind')
            local cmp_autopairs = require('nvim-autopairs.completion.cmp')

            cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())

            local source_mapping = {
                buffer = "[Buf]",
                nvim_lsp = "[LSP]",
                vsnip = "[Sni]",
                treesitter = "[TS]",
                cmp_tabnine = "[TAB]",
                path = "[Path]",
            }

            local has_words_before = function()
                unpack = unpack or table.unpack
                local line, col = unpack(vim.api.nvim_win_get_cursor(0))
                return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
            end

            local feedkey = function(key, mode)
                vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, true, true), mode, true)
            end

            cmp.setup({
                snippet = {
                    expand = function(args)
                        vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
                    ['<C-f>'] = cmp.mapping.scroll_docs(4),
                    ['<C-Space>'] = cmp.mapping.complete(),
                    ['<C-e>'] = cmp.mapping.abort(),
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

                    ["<Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_next_item()
                        elseif vim.fn["vsnip#available"](1) == 1 then
                            feedkey("<Plug>(vsnip-expand-or-jump)", "")
                        elseif has_words_before() then
                            cmp.complete()
                        else
                            fallback() -- The fallback function sends a already mapped key. In this case, it's probably `<Tab>`.
                        end
                    end, { "i", "s" }),

                    ["<S-Tab>"] = cmp.mapping(function()
                        if cmp.visible() then
                            cmp.select_prev_item()
                        elseif vim.fn["vsnip#jumpable"](-1) == 1 then
                            feedkey("<Plug>(vsnip-jump-prev)", "")
                        end
                    end, { "i", "s" }),
                    -- ['<CR>'] = cmp.mapping.confirm({ select = false }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
                    -- ['<Tab>'] = vim.schedule_wrap(function(fallback)
                        --     if cmp.visible() and has_words_before() then
                        --         cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
                        --     else
                        --         fallback()
                        --     end
                        -- end),
                    }),
                    sources = cmp.config.sources({
                        { name = 'nvim_lsp' },
                        { name = 'vsnip' }, -- For vsnip users.
                        { name = 'cmp_tabnine' },
                        { name = 'treesitter' },
                        { name = 'nvim_lsp_signature_help' },
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
                        { name = 'nvim_lsp_document_symbol' }
                    },
                    {
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
                            option = {
                                ignore_cmds = { 'Man', '!' }
                            }
                        }
                    })
                })
            end
        }

        use {
            'tzachar/cmp-tabnine',
            run='./install.sh',
            requires = 'hrsh7th/nvim-cmp',
            config = function()
                require('cmp_tabnine.config'):setup({
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

        -- 対応する括弧を自動挿入する
        use {
            "windwp/nvim-autopairs",
            config = function() require("nvim-autopairs").setup {} end
        }
    end

    return M;

