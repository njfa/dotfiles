local M = {}

function M.setup()
    local colors = require("tokyonight.colors").setup() -- pass in any of the config options as explained above

    require("scope").setup()

    require("bufferline").setup {
        highlights = {
            fill = {
                fg = colors.fg,
                bg = colors.bg_highlight,
            },
            background = {
                fg = colors.comment,
                bg = "#1f2335",
            },
            buffer = {
                fg = colors.fg,
                bg = colors.bg_highlight,
            },
            tab = {
                fg = colors.comment,
                bg = "#1f2335",
            },
            tab_selected = {
                fg = colors.bg_dark,
                bg = colors.blue,
            },
            tab_separator = {
                fg = "#1f2335",
                bg = "#1f2335",
            },
            tab_separator_selected = {
                fg = colors.blue,
                bg = colors.blue,
            },
            -- close_button = {
            --     fg = colors.fg,
            --     bg = colors.bg,
            -- },
        --     close_button_selected = {
        --         fg = colors.fg,
        --         bg = colors.bg_highlight,
        --     },
            separator = {
                fg = colors.bg_highlight,
                bg = colors.bg_highlight,
            },
        --     separator_selected = {
        --         fg = colors.fg,
        --         bg = colors.bg_highlight,
        --     },
        --     -- separator_visible = {
        --     --     fg = colors.fg,
        --     --     bg = colors.bg,
        --     -- },
            offset_separator = {
                fg = colors.bg_dark,
                bg = colors.bg_highlight,
            },
        --     indicator_visible = {
        --         fg = colors.fg,
        --         bg = colors.bg_highlight,
        --     },
        --     indicator_selected = {
        --         fg = colors.fg,
        --         bg = colors.bg_highlight,
        --     },
            diagnostic = {
                bg = "#1f2335",
            },
            diagnostic_visible = {
                bg = "#1f2335",
            },
            hint = {
                bg = "#1f2335",
            },
            hint_visible = {
                bg = "#1f2335",
            },
            info = {
                bg = "#1f2335",
            },
            warning = {
                bg = "#1f2335",
            },
            error = {
                bg = "#1f2335",
            },
            info_visible = {
                bg = "#1f2335",
            },
            warning_visible = {
                bg = "#1f2335",
            },
            error_visible = {
                bg = "#1f2335",
            },
            hint_diagnostic = {
                bg = "#1f2335",
            },
            hint_diagnostic_visible = {
                bg = "#1f2335",
            },
            info_diagnostic = {
                bg = "#1f2335",
            },
            info_diagnostic_visible = {
                bg = "#1f2335",
            },
            warning_diagnostic = {
                bg = "#1f2335",
            },
            warning_diagnostic_visible = {
                bg = "#1f2335",
            },
            error_diagnostic = {
                bg = "#1f2335",
            },
            error_diagnostic_visible = {
                bg = "#1f2335",
            },
        --     hint_diagnostic_selected = {
        --         bold = true,
        --         italic = false,
        --         bg = colors.bg_highlight,
        --     },
        --
            duplicate = {
                bg = "#1f2335",
            },
            duplicate_visible = {
                bg = "#1f2335",
            },
        },
        options = {
            -- numbers = "buffer_id",
            numbers = "none",
            -- numbers = function(opts)
            --     return string.format(' %s|%s', opts.id, opts.raise(opts.ordinal))
            -- end,
            -- numbers = function()
            --     return ''
            -- end,
            -- buffer_close_icon = '',
            buffer_close_icon = 'ⅹ ',
            max_name_length = 20,
            max_prefix_length = 10, -- prefix used when a buffer is de-duplicated
            truncate_names = true, -- whether or not tab names should be truncated
            tab_size = 10,
            color_icons = true,
            sort_by = 'insert_after_current',
            always_show_bufferline = true,
            separator_style = { ' ', ' ' },
            show_tab_indicators = true,
            indicator = {
                icon = "▌",
                style = 'icon'
            },
            diagnostics = "nvim_lsp",
            diagnostics_indicator = function(count, level, diagnostics_dict, context)
                local s = ""
                for e, n in pairs(diagnostics_dict) do
                    local sym = e == "error" and " "
                    or (e == "warning" and " " or e == "info" and " " or " " )
                    s = s .. sym .. n .. ''
                end
                return s
            end,
            offsets = {
                {
                    filetype = "fern",
                    text = "EXPLORER",
                    text_align = "center",
                    highlight = "MatchParen",
                    separator = true
                },
                {
                    filetype = "aerial",
                    text = "OUTLINE",
                    text_align = "center",
                    highlight = "MatchParen",
                    separator = true
                },
                {
                    filetype = "sagaoutline",
                    text = "OUTLINE",
                    text_align = "center",
                    highlight = "MatchParen",
                    separator = true
                }
            },
            hover = {
                enabled = true,
                delay = 200,
                reveal = {'close'}
            },
        }
    }
end

return M;
