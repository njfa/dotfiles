local M = {}

function M.load(use)
    -- 色定義の追加
    use 'folke/lsp-colors.nvim'

    -- LSPサーバー管理
    use {
        'williamboman/mason.nvim',
        requires = {
            'neovim/nvim-lspconfig',
            'williamboman/mason-lspconfig.nvim',
            'hrsh7th/cmp-nvim-lsp',
        },
        config = function()
            -- mason
            require('mason').setup()
            require('mason-lspconfig').setup()
            require("mason-lspconfig").setup_handlers {
                function (server_name)
                    -- Setup lspconfig.
                    require("lspconfig")[server_name].setup {
                        on_attach = on_attach_lsp,
                        capabiritty = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())
                    }
                end,
            }
        end
    }

    use {
        'nvimdev/lspsaga.nvim',
        requires = 'nvim-lspconfig',
        config = function()
            require('lspsaga').setup({
                finder = {
                    max_height = 0.6,
                    keys = {
                        vsplit = 'e',
                        toggle_or_open = '<cr>',
                    },
                    methods = {
                        tyd = 'textDocument/typeDefinition'
                    },
                    default = 'def+ref+imp+tyd'
                },
                hover = {
                    open_cmd = '!browser.sh'
                },
                outline = {
                    auto_preview = false,
                    auto_close = false,
                    detail = true,
                    win_position = 'left',
                    keys = {
                        jump = '<cr>'
                    }
                }
            })
        end,
    }

    use {
        "ray-x/lsp_signature.nvim",
        config = function()
            local cfg = {
                hint_prefix = " ",
                floating_window_off_x = 5, -- adjust float windows x position.
                floating_window_off_y = function() -- adjust float windows y position. e.g. set to -2 can make floating window move up 2 lines
                    local linenr = vim.api.nvim_win_get_cursor(0)[1] -- buf line number
                    local pumheight = vim.o.pumheight
                    local winline = vim.fn.winline() -- line number in the window
                    local winheight = vim.fn.winheight(0)

                    -- window top
                    if winline - 1 < pumheight then
                        return pumheight
                    end

                    -- window bottom
                    if winheight - winline < pumheight then
                        return -pumheight
                    end
                    return 0
                end,
            }
            require("lsp_signature").setup(cfg)
        end
    }
end

return M;
