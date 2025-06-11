local vscode_enabled, _ = pcall(require, "vscode")

-- 環境変数で明示的に有効化している場合のみcopilotを利用した補完を利用する
local cmp_copilot_enabled = function()
    local cmp_copilot_enabled = vim.env.CMP_COPILOT_ENABLED
    local is_cmp_copilot_enabled = false
    if cmp_copilot_enabled then
        is_cmp_copilot_enabled = string.lower(cmp_copilot_enabled) == "true"
    end

    return vim.g.llm_enabled and is_cmp_copilot_enabled
end

local default_sources = { 'path', 'snippets', 'lsp', 'buffer', 'markdown' }
local source_providers = {
    buffer = {
        name = "buf",
        score_offset = 0,
    },
    markdown = {
        name = 'RenderMarkdown',
        module = 'render-markdown.integ.blink',
        fallbacks = { 'lsp' },
    },
}

if cmp_copilot_enabled() then
    table.insert(default_sources, 'copilot')
    source_providers['copilot'] = {
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
    }
end

return {
    {
        'saghen/blink.compat',
        -- use the latest release, via version = '*', if you also use the latest release for blink.cmp
        version = '*',
        -- lazy.nvim will automatically load the plugin when it's required by blink.cmp
        lazy = true,
        -- make sure to set opts so that lazy.nvim calls blink.compat's setup
        opts = {},
        cond = not vscode_enabled,
    },
    {
        'saghen/blink.cmp',
        -- optional: provides snippets for the snippet source
        dependencies = {
            'L3MON4D3/LuaSnip',
            {
                "giuxtaposition/blink-cmp-copilot",
                cond = vim.g.cmp_copilot_enabled
            }
        },
        cond = not vscode_enabled,

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
                        auto_insert = true
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
                    update_delay_ms = 50,
                },
                ghost_text = {
                    enabled = true,
                }
            },

            -- Default list of enabled providers defined so that you can extend it
            -- elsewhere in your config, without redefining it, due to `opts_extend`
            sources = {
                default = default_sources,
                providers = source_providers
            },

            cmdline = {
                keymap = {
                    preset = 'cmdline',
                    ['<Up>'] = { 'select_prev', 'fallback' },
                    ['<Down>'] = { 'select_next', 'fallback' },
                    ['<Left>'] = { 'cancel', 'fallback' },
                    ['<Right>'] = { 'hide', 'fallback' },
                },
                sources = function()
                    local type = vim.fn.getcmdtype()
                    -- Search forward and backward
                    if type == '/' or type == '?' then return { 'buffer' } end
                    -- Commands
                    if type == ':' or type == '@' then return { 'cmdline' } end
                    return {}
                end,
                completion = {
                    list = {
                        selection = {
                            -- When `true`, will automatically select the first item in the completion list
                            preselect = false,
                            -- When `true`, inserts the completion item automatically when selecting it
                            auto_insert = true,
                        },
                    },
                    -- Whether to automatically show the window when new completion items are available
                    menu = { auto_show = true },
                    -- Displays a preview of the selected item on the current line
                    ghost_text = { enabled = true }
                }
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
}
