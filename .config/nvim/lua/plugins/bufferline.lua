local M = {}

function M.load()
    require("scope").setup()

    -- ' ' ' ' ' ' ' '
    require("bufferline").setup {
        highlights = {
            buffer_selected = {
                bold = true,
                italic = true,
            },
            tab_selected = {
                bold = true,
                italic = true,
            },
        },
        options = {
            numbers = "buffer_id",
            buffer_close_icon = '',
            max_name_length = 100,
            max_prefix_length = 15, -- prefix used when a buffer is de-duplicated
            truncate_names = true, -- whether or not tab names should be truncated
            tab_size = 0,
            indicator = {
                icon = '▎', -- this should be omitted if indicator style is not 'icon'
                -- style = 'underline'
            },
            diagnostics = "nvim_lsp",
            diagnostics_indicator = function(count, level, diagnostics_dict, context)
                local s = ""
                for e, n in pairs(diagnostics_dict) do
                    local sym = e == "error" and ""
                    or (e == "warning" and " " or e == "info" and " " or " " )
                    s = s .. sym .. n .. ' '
                end
                return s
            end,
            offsets = {
                {
                    filetype = "fern",
                    text = function()
                        return vim.fn.getcwd()
                    end,
                    highlight = "Directory",
                    text_align = "left"
                }
            },
            -- sort_by = 'insert_after_current'
        }
    }
end

return M;
