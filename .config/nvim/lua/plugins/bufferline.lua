-- bufferlineでタブバーを表示する
-- 設定が多いため、別ファイルに切り出し
return {
    'akinsho/bufferline.nvim',
    dependencies = {
        'nvim-tree/nvim-web-devicons',
        'tiagovla/scope.nvim',
    },
    config = function()
        local colors = require("tokyonight.colors").setup() -- pass in any of the config options as explained above

        require("bufferline").setup {
            highlights = {
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
                }
            },
            options = {
                numbers = "none",
                name_formatter = function(buf)  -- buf contains:
                    return buf.name
                end,
                get_element_icon = function(element)
                    -- element consists of {filetype: string, path: string, extension: string, directory: string}
                    -- This can be used to change how bufferline fetches the icon
                    -- for an element e.g. a buffer or a tab.
                    -- e.g.
                    local icon, hl = require('nvim-web-devicons').get_icon_by_filetype(element.filetype, { default = false })
                    if icon then
                        return " " .. icon .. " ", hl
                    else
                        return "  ", hl
                    end
                end,
                show_buffer_close_icons = true,
                show_close_icon = true,
                max_name_length = 20,
                max_prefix_length = 10, -- prefix used when a buffer is de-duplicated
                truncate_names = true, -- whether or not tab names should be truncated
                tab_size = 10,
                color_icons = true,
                sort_by = 'insert_after_current',
                show_tab_indicators = true,
                separator_style = 'thick',
                indicator = {
                    icon = "▌",
                    style = 'icon'
                },
                diagnostics = "nvim_lsp",
                -- diagnostics_indicator = function(count, level, diagnostics_dict, context)
                diagnostics_indicator = function(_, _, diagnostics_dict, _)
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
                -- WindowsTerminalではhoverイベントが効かないため無効かする
                hover = {
                    enabled = false,
                    -- delay = 200,
                    -- reveal = {'close'}
                },
            }
        }
    end
}
