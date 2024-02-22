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
            separator = {
                fg = colors.fg,
                bg = colors.bg,
            },
            separator_selected = {
                fg = colors.fg,
                bg = colors.bg,
            },
            separator_visible = {
                fg = colors.fg,
                bg = colors.bg,
            },
            offset_separator = {
                fg = colors.bg_dark,
                bg = colors.bg,
            },
            indicator_visible = {
                fg = colors.fg,
                bg = colors.bg,
            },
            indicator_selected = {
                fg = colors.fg,
                bg = colors.bg,
            },
            background = {
                fg = colors.dark5,
                bg = colors.bg,
            },
            buffer_selected = {
                fg = colors.fg,
            },
            tab = {
                fg = colors.fg,
                bold = false,
                italic = false,
            },
            tab_selected = {
                fg = colors.bg_dark,
                bg = colors.purple,
                bold = true,
                italic = true,
            },
            tab_separator = {
                fg = colors.bg_dark,
            },
            tab_separator_selected = {
                fg = colors.purple,
            },
            diagnostic_selected = {
                bold = true,
                italic = false,
            },
            hint_selected = {
                bold = true,
                italic = false,
            },
            hint_diagnostic_selected = {
                bold = true,
                italic = false,
            },
        },
        options = {
            -- numbers = "buffer_id",
            -- numbers = "none",
            -- numbers = function(opts)
            --     return string.format(' %s|%s', opts.id, opts.raise(opts.ordinal))
            -- end,
            numbers = function()
                return ''
            end,
            buffer_close_icon = '',
            max_name_length = 20,
            max_prefix_length = 10, -- prefix used when a buffer is de-duplicated
            truncate_names = true, -- whether or not tab names should be truncated
            tab_size = 10,
            color_icons = true,
            sort_by = 'insert_after_current',
            always_show_bufferline = true,
            separator_style = { '┊ ', '┊ ' },
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
