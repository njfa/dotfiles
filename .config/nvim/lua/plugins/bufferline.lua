local M = {}

function M.load()
    require("scope").setup()

    -- ' ' ' ' ' ' ' '
    require("bufferline").setup {
        highlights = {
            buffer_selected = {
                bold = true,
                italic = false,
            },
            tab_selected = {
                bold = true,
                italic = false,
            },
            tab_separator = {
              fg = '#ffffff',
              bg = '#000000',
            },
            tab_separator_selected = {
              fg = '#ffffff',
              bg = '#000000',
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
            numbers = "none",
            buffer_close_icon = '',
            max_name_length = 20,
            max_prefix_length = 10, -- prefix used when a buffer is de-duplicated
            truncate_names = true, -- whether or not tab names should be truncated
            tab_size = 10,
            color_icons = true,
            sort_by = 'insert_after_current',
            always_show_bufferline = true,
            separator_style = { '┊ ', '┊ ' },
            show_tab_indicators = false,
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
                    text = "File Explorer",
                    text_align = "center",
                    highlight = "MatchParen",
                    separator = true
                },
                {
                    filetype = "aerial",
                    text = "Outline",
                    text_align = "center",
                    highlight = "MatchParen",
                    separator = true
                },
                {
                    filetype = "sagaoutline",
                    text = "Lspsaga Outline",
                    text_align = "center",
                    highlight = "MatchParen",
                    separator = true
                }
                -- {
                --     filetype = "fern",
                --     text = function()
                --         return vim.fn.getcwd()
                --     end,
                --     highlight = "Directory",
                --     text_align = "left"
                -- }
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
