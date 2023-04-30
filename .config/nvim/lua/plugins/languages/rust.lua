local M = {}

function M.load(use)
    use {
        'simrat39/rust-tools.nvim',
        requires = {
            'neovim/nvim-lspconfig',
            'williamboman/mason.nvim',
        },
        config = function ()
            -- local codelldb_path = require("mason-registry").get_package("codelldb"):get_install_path() .. "/extension"
            local codelldb_path = vim.fn.stdpath('data') .. "/mason/packages/codelldb/extension"
            local codelldb_bin = codelldb_path .. "/adapter/codelldb"
            local liblldb_bin = codelldb_path .. "/lldb/lib/liblldb.so"

            local rt = require('rust-tools')

            local cfg = {
                server = {
                    settings = {
                        ['rust-analyzer'] = {
                            cargo = {
                                autoReload = true
                            }
                        }
                    },
                },
                dap = {
                    adapter = require('rust-tools.dap').get_codelldb_adapter(
                        codelldb_bin,
                        liblldb_bin
                    )
                }
            }

            rt.setup(cfg)

            require('dap.ext.vscode').load_launchjs(nil, {rt_lldb={'rust'}})
        end
    }
end

return M;
