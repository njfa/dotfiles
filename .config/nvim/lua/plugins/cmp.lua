return {
    {
        'saghen/blink.compat',
        -- use the latest release, via version = '*', if you also use the latest release for blink.cmp
        version = '*',
        -- lazy.nvim will automatically load the plugin when it's required by blink.cmp
        lazy = true,
        -- make sure to set opts so that lazy.nvim calls blink.compat's setup
        opts = {},
    },
    {
        'saghen/blink.cmp',
        -- optional: provides snippets for the snippet source
        dependencies = {
            'L3MON4D3/LuaSnip',
            "giuxtaposition/blink-cmp-copilot",
        },

        -- use a release tag to download pre-built binaries
        version = '*',
        -- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
        -- build = 'cargo build --release',
        -- If you use nix, you can build from source using latest nightly rust with:
        -- build = 'nix run .#build-plugin',

        ---@module 'blink.cmp'
        opts = {
            -- 'default' for mappings similar to built-in completion
            -- 'super-tab' for mappings similar to vscode (tab to accept, arrow keys to navigate)
            -- 'enter' for mappings similar to 'super-tab' but with 'enter' to accept
            -- See the full "keymap" documentation for information on defining your own keymap.
            keymap = {
                preset = 'default',
                ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
                ['<C-e>'] = { 'cancel', 'fallback' },
                ['<Tab>'] = {
                    function(cmp)
                        if cmp.snippet_active() then
                            return cmp.accept()
                        else
                            return cmp.select_and_accept()
                        end
                    end,
                    'fallback'
                },

                ['<C-j>'] = { 'snippet_forward', 'fallback' },
                ['<C-k>'] = { 'snippet_backward', 'fallback' },

                ['<Up>'] = { 'select_prev', 'fallback' },
                ['<Down>'] = { 'select_next', 'fallback' },
                ['<C-p>'] = { 'select_prev', 'fallback' },
                ['<C-n>'] = { 'select_next', 'fallback' },

                ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
                ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },

                ['<C-d>'] = { 'show_documentation', 'hide_documentation', 'fallback' },
            },

            appearance = {
                -- Set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
                -- Adjusts spacing to ensure icons are aligned
                nerd_font_variant = 'normal',
                -- Blink does not expose its default kind icons so you must copy them all (or set your custom ones) and add Copilot
                kind_icons = {
                    Copilot = "󱐋",
                    Text = '󰉿',
                    Method = '󰊕',
                    Function = '󰊕',
                    Constructor = '󰒓',

                    Field = '󰜢',
                    Variable = '󰆦',
                    Property = '󰖷',

                    Class = '󱡠',
                    Interface = '󱡠',
                    Struct = '󱡠',
                    Module = '󰅩',

                    Unit = '󰪚',
                    Value = '󰦨',
                    Enum = '󰦨',
                    EnumMember = '󰦨',

                    Keyword = '󰻾',
                    Constant = '󰏿',

                    Snippet = '󱄽',
                    Color = '󰏘',
                    File = '󰈔',
                    Reference = '󰬲',
                    Folder = '󰉋',
                    Event = '󱐋',
                    Operator = '󰪚',
                    TypeParameter = '󰬛',
                },
            },

            completion = {
                keyword = {
                    range = 'prefix'
                },
                list = {
                    selection = {
                        preselect = false,
                        auto_insert = false
                    }
                },
                trigger = {},
                menu = {
                    max_height = 20,
                    draw = {
                        padding = 1,
                        gap = 1,
                        treesitter = { 'lsp' },
                        columns = { { 'kind_icon' }, { 'label', 'label_description', gap = 1 }, { 'kind' } },
                        components = {
                            source_name = {
                                -- text = function(ctx) return string.sub(ctx.source_name, 1, 3) end,
                            }
                        }
                    },
                    -- winhighlight = 'Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None',
                },
                documentation = {
                    auto_show = true,
                    auto_show_delay_ms = 0,
                    update_delay_ms = 0,
                },
                ghost_text = {
                    enabled = true,
                }
            },

            -- Default list of enabled providers defined so that you can extend it
            -- elsewhere in your config, without redefining it, due to `opts_extend`
            sources = {
                default = { 'path', 'copilot', 'snippets', 'lsp', 'buffer' },
                cmdline = function()
                    local type = vim.fn.getcmdtype()
                    -- Search forward and backward
                    if type == '/' or type == '?' then return { 'buffer' } end
                    -- Commands
                    if type == ':' or type == '@' then return { 'cmdline' } end
                    return {}
                end,
                providers = {
                    buffer = {
                        name = "buf",
                        score_offset = 0,
                    },
                    copilot = {
                        name = "copilot",
                        module = "blink-cmp-copilot",
                        score_offset = 100,
                        async = true,
                        transform_items = function(_, items)
                            local CompletionItemKind = require("blink.cmp.types").CompletionItemKind
                            local kind_idx = #CompletionItemKind + 1
                            CompletionItemKind[kind_idx] = "Copilot"
                            for _, item in ipairs(items) do
                                item.kind = kind_idx
                            end
                            return items
                        end,
                    },
                },
            },

            snippets = { preset = 'luasnip' },
            signature = {
                enabled = true,
                trigger = {
                    show_on_insert = true,
                },
                window = {
                    show_documentation = true
                }
            }
        },
        opts_extend = { "sources.default" }
    }
    -- -- 自動補完
    -- {
    --     'hrsh7th/nvim-cmp',
    --     dependencies = {
    --         'neovim/nvim-lspconfig',
    --         'hrsh7th/cmp-nvim-lsp',
    --         'hrsh7th/cmp-buffer',
    --         'hrsh7th/cmp-path',
    --         'hrsh7th/cmp-cmdline',
    --         'hrsh7th/cmp-nvim-lsp-signature-help',
    --         'L3MON4D3/LuaSnip',
    --         'saadparwaiz1/cmp_luasnip',
    --         -- 'hrsh7th/cmp-vsnip',
    --         -- 'hrsh7th/vim-vsnip',
    --         'ray-x/cmp-treesitter',
    --         -- 'hrsh7th/cmp-nvim-lsp-document-symbol', -- lsp_signagureと役割が重複するのでコメントアウト
    --         -- 'hrsh7th/cmp-nvim-lsp-signature-help', -- lsp_signagureと役割が重複するのでコメントアウト
    --         'petertriho/cmp-git',
    --         'onsails/lspkind.nvim',
    --         {
    --             "zbirenbaum/copilot-cmp",
    --             config = function()
    --                 require("copilot_cmp").setup()
    --             end
    --         }
    --     },
    --     config = function()
    --         -- nvim-cmpの設定
    --         local cmp = require("cmp")
    --         local lspkind = require('lspkind')
    --         local cmp_autopairs = require('nvim-autopairs.completion.cmp')

    --         cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())

    --         local source_mapping = {
    --             buffer = "[Buf]",
    --             copilot = "[AI]",
    --             nvim_lsp = "[LSP]",
    --             -- vsnip = "[Snip]",
    --             luasnip = "[Snip]",
    --             treesitter = "[TS]",
    --             -- cmp_tabnine = "[TAB]",
    --             path = "[Path]",
    --         }

    --         local has_words_before = function()
    --             local line, col = table.unpack(vim.api.nvim_win_get_cursor(0))
    --             return col ~= 0 and
    --                 vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
    --         end

    --         cmp.setup({
    --             snippet = {
    --                 expand = function(args)
    --                     -- vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
    --                     require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
    --                 end,
    --             },
    --             window = {
    --                 completion = cmp.config.window.bordered(),
    --                 documentation = cmp.config.window.bordered(),
    --             },
    --             mapping = cmp.mapping.preset.insert({
    --                 ['<C-p>'] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
    --                 ['<C-n>'] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
    --                 ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    --                 ['<C-f>'] = cmp.mapping.scroll_docs(4),
    --                 ['<C-Space>'] = cmp.mapping.complete(),
    --                 ['<C-e>'] = cmp.mapping.close(),
    --                 ["<CR>"] = cmp.mapping({
    --                     i = function(fallback)
    --                         if cmp.visible() and cmp.get_active_entry() then
    --                             cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false })
    --                         else
    --                             fallback()
    --                         end
    --                     end,
    --                     s = cmp.mapping.confirm({ select = true }),
    --                     c = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false }),
    --                 }),

    --                 ["<C-j>"] = cmp.mapping(function(fallback)
    --                     if cmp.visible() then
    --                         cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
    --                     elseif require('luasnip').expandable() then
    --                         require('luasnip').expand()
    --                     elseif require('luasnip').jumpable(1) then
    --                         require('luasnip').jump(1)
    --                         -- elseif vim.fn["vsnip#available"](1) == 1 then
    --                         --     feedkey("<Plug>(vsnip-expand-or-jump)", "")
    --                     elseif has_words_before() then
    --                         cmp.complete()
    --                     else
    --                         fallback() -- The fallback function sends a already mapped key. In this case, it's probably `<Tab>`.
    --                     end
    --                 end, { "i", "s" }),

    --                 ["<C-k>"] = cmp.mapping(function()
    --                     if cmp.visible() then
    --                         cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
    --                     elseif require('luasnip').jumpable(-1) then
    --                         require('luasnip').jump(-1)
    --                         -- elseif vim.fn["vsnip#jumpable"](-1) == 1 then
    --                         --     feedkey("<Plug>(vsnip-jump-prev)", "")
    --                     end
    --                 end, { "i", "s" }),

    --                 ["<Tab>"] = cmp.mapping(function(fallback)
    --                     if cmp.visible() then
    --                         cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
    --                     elseif require('luasnip').expandable() then
    --                         require('luasnip').expand()
    --                     elseif require('luasnip').jumpable(1) then
    --                         require('luasnip').jump(1)
    --                         -- elseif vim.fn["vsnip#available"](1) == 1 then
    --                         --     feedkey("<Plug>(vsnip-expand-or-jump)", "")
    --                     elseif has_words_before() then
    --                         cmp.complete()
    --                     else
    --                         fallback() -- The fallback function sends a already mapped key. In this case, it's probably `<Tab>`.
    --                     end
    --                 end, { "i", "s" }),

    --                 ["<S-Tab>"] = cmp.mapping(function()
    --                     if cmp.visible() then
    --                         cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
    --                     elseif require('luasnip').jumpable(-1) then
    --                         require('luasnip').jump(-1)
    --                     end
    --                 end, { "i", "s" }),
    --             }),

    --             sources = cmp.config.sources({
    --                 { name = 'copilot' },
    --                 { name = 'nvim_lsp_signature_help' },
    --                 { name = 'nvim_lsp' },
    --                 { name = 'luasnip' }, -- For luasnip users.
    --             }, {
    --                 { name = 'treesitter' },
    --                 { name = 'buffer' },
    --             }),
    --             formatting = {
    --                 format = lspkind.cmp_format({
    --                     mode = 'symbol_text',
    --                     maxwidth = 50, -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)

    --                     before = function(entry, vim_item)
    --                         vim_item.kind = lspkind.presets.default[vim_item.kind]
    --                         local menu = source_mapping[entry.source.name]
    --                         if entry.source.name == "cmp_tabnine" then
    --                             if entry.completion_item.data ~= nil and entry.completion_item.data.detail ~= nil then
    --                                 menu = entry.completion_item.data.detail .. " " .. menu
    --                             end
    --                             vim_item.kind = ""
    --                         end
    --                         vim_item.menu = menu
    --                         return vim_item
    --                     end,
    --                 })
    --             },
    --             sorting = {
    --                 priority_weight = 3,
    --             },
    --         })

    --         -- Set configuration for specific filetype.
    --         cmp.setup.filetype('gitcommit', {
    --             sources = cmp.config.sources({
    --                 { name = 'cmp_git' }, -- You can specify the `cmp_git` source if you were installed it.
    --             }, {
    --                 { name = 'buffer' },
    --             })
    --         })

    --         -- buffer source for `/` (if you enabled `native_menu`, this won't work anymore).
    --         cmp.setup.cmdline('/', {
    --             mapping = cmp.mapping.preset.cmdline(),
    --             sources = {
    --                 { name = 'nvim_lsp_document_symbol' }
    --             },
    --             {
    --                 { name = 'buffer' }
    --             }
    --         })

    --         -- cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
    --         cmp.setup.cmdline(':', {
    --             mapping = cmp.mapping.preset.cmdline(),
    --             sources = cmp.config.sources({
    --                 { name = 'path' }
    --             }, {
    --                 {
    --                     name = 'cmdline',
    --                     option = {
    --                         ignore_cmds = { 'Man', '!' }
    --                     }
    --                 }
    --             })
    --         })

    --         require("luasnip.loaders.from_vscode").lazy_load()
    --     end
    -- },
}
