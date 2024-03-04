local M = {}

function M.load(use)
    -- 色定義の追加
    use 'folke/lsp-colors.nvim'

    use {
        "https://git.sr.ht/~whynothugo/lsp_lines.nvim",
        config = function()
            vim.diagnostic.config({
                virtual_text = false,
            })
            require("lsp_lines").setup()
        end,
    }

    -- LSPサーバー管理
    use {
        'williamboman/mason.nvim',
        'neovim/nvim-lspconfig',
        'hrsh7th/cmp-nvim-lsp',
        'jose-elias-alvarez/null-ls.nvim',
        {
            'williamboman/mason-lspconfig.nvim',
            requires = {
                'williamboman/mason.nvim',
                'hrsh7th/cmp-nvim-lsp',
                'jose-elias-alvarez/null-ls.nvim',
                'mfussenegger/nvim-jdtls',
                'simrat39/rust-tools.nvim',
            },
            -- ft = {'sh', 'zsh', 'bash', 'html', 'markdown', 'vim', 'lua', 'yaml', 'env', 'json', 'javascript'},
            config = function()
                -- mason
                require('mason').setup()
                require('mason-lspconfig').setup()
                require("mason-lspconfig").setup_handlers {
                    function (server_name)
                        -- Setup lspconfig.
                        if server_name ~= "jdtls" then
                            require("lspconfig")[server_name].setup {
                                on_attach = on_attach_lsp,
                                capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())
                            }
                        end
                        require("notify")("server_name: " .. server_name)
                    end,

                    -- ["jdtls"] = function()
                    --     local jdtls_path = vim.fn.stdpath('data') .. "/mason/packages/jdtls/bin/jdtls"
                    --     local java_debugger_path = vim.fn.stdpath('data') .. "/mason/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar"

                    --     local cfg = {
                    --         cmd = { jdtls_path },
                    --         root_dir = vim.fs.dirname(vim.fs.find({'gradlew', '.git', 'mvnw'}, { upward = true })[1]),
                    --         init_options = {
                    --             bundles = {
                    --                 vim.fn.glob(java_debugger_path, true)
                    --             };
                    --         },
                    --         on_attach = function(client, bufnr)
                    --             -- require('jdtls').setup_dap({ hotcodereplace = 'auto' })
                    --             on_attach_lsp(client, bufnr)
                    --         end
                    --     }

                    --     require('jdtls').start_or_attach(cfg)

                    --     -- require('dap').configurations.java = {
                    --     --     {
                    --     --         type = 'java';
                    --     --         request = 'launch';
                    --     --         name = "Debug (Attach) - Remote";
                    --     --         hostName = '127.0.0.1';
                    --     --         port = 5005;
                    --     --     },
                    --     -- }
                    -- end,

                    ["rust_analyzer"] = function ()
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

                        -- require('dap.ext.vscode').load_launchjs(nil, {rt_lldb={'rust'}})
                        require('dap').configurations.rust = {
                            {
                                type = 'rt_lldb';
                                request = 'launch';
                                name = "Debug (Attach)";
                                cwd = "${workspaceFolder}",
                                program = "${workspaceFolder}/target/debug/${workspaceFolderBasename}",
                                stopAtEntry = true,
                            },
                        }
                    end,

                    ["pylsp"] = function()
                        require("lspconfig").pylsp.setup {
                            settings = {
                                pylsp = {
                                    plugins = {
                                        pycodestyle = {
                                            ignore = {'E501'}
                                        }
                                    }
                                }
                            },
                            on_attach = on_attach_lsp,
                            capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())
                        }
                    end
                }

                -- Formatterのセットアップ
                local mason = require("mason")
                local mason_package = require("mason-core.package")
                local mason_registry = require("mason-registry")
                local null_ls = require("null-ls")

                local null_sources = {
                    null_ls.builtins.diagnostics.markdownlint.with({
                        extra_args = { "--disable", "MD007", "MD012", "MD013" }
                    })
                }

                for _, package in ipairs(mason_registry.get_installed_packages()) do
                    local package_categories = package.spec.categories[1]
                    if package_categories == mason_package.Cat.Formatter then
                        table.insert(null_sources, null_ls.builtins.formatting[package.name])
                    end
                    if package_categories == mason_package.Cat.Linter then
                        table.insert(null_sources, null_ls.builtins.diagnostics[package.name])
                    end
                end

                null_ls.setup({
                    sources = null_sources,
                })
            end
        },
        -- {
        --     -- JavaのLSPについては専用のものを利用する
        --     'mfussenegger/nvim-jdtls',
        --     requires = {
        --         'williamboman/mason.nvim',
        --     },
        --     ft = { "java" },
        --     config = function ()
        --         local jdtls_path = vim.fn.stdpath('data') .. "/mason/packages/jdtls/bin/jdtls"
        --         local java_debugger_path = vim.fn.stdpath('data') .. "/mason/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar"

        --         local cfg = {
        --             cmd = { jdtls_path },
        --             root_dir = vim.fs.dirname(vim.fs.find({'gradlew', '.git', 'mvnw'}, { upward = true })[1]),
        --             init_options = {
        --                 bundles = {
        --                     vim.fn.glob(java_debugger_path, true)
        --                 };
        --             },
        --             on_attach = function(client, bufnr)
        --                 -- require('jdtls').setup_dap({ hotcodereplace = 'auto' })
        --                 on_attach_lsp(client, bufnr)
        --             end
        --         }

        --         require('jdtls').start_or_attach(cfg)

        --         -- require('dap').configurations.java = {
        --         --     {
        --         --         type = 'java';
        --         --         request = 'launch';
        --         --         name = "Debug (Attach) - Remote";
        --         --         hostName = '127.0.0.1';
        --         --         port = 5005;
        --         --     },
        --         -- }
        --     end
        -- },
        -- {
        --     'simrat39/rust-tools.nvim',
        --     requires = {
        --         'neovim/nvim-lspconfig',
        --         'williamboman/mason.nvim',
        --     },
        --     ft = {
        --         "rust"
        --     },
        --     config = function ()
        --         -- local codelldb_path = require("mason-registry").get_package("codelldb"):get_install_path() .. "/extension"
        --         local codelldb_path = vim.fn.stdpath('data') .. "/mason/packages/codelldb/extension"
        --         local codelldb_bin = codelldb_path .. "/adapter/codelldb"
        --         local liblldb_bin = codelldb_path .. "/lldb/lib/liblldb.so"

        --         local rt = require('rust-tools')

        --         local cfg = {
        --             server = {
        --                 settings = {
        --                     ['rust-analyzer'] = {
        --                         cargo = {
        --                             autoReload = true
        --                         }
        --                     }
        --                 },
        --             },
        --             dap = {
        --                 adapter = require('rust-tools.dap').get_codelldb_adapter(
        --                     codelldb_bin,
        --                     liblldb_bin
        --                 )
        --             }
        --         }

        --         rt.setup(cfg)

        --         -- require('dap.ext.vscode').load_launchjs(nil, {rt_lldb={'rust'}})
        --         require('dap').configurations.rust = {
        --             {
        --                 type = 'rt_lldb';
        --                 request = 'launch';
        --                 name = "Debug (Attach)";
        --                 cwd = "${workspaceFolder}",
        --                 program = "${workspaceFolder}/target/debug/${workspaceFolderBasename}",
        --                 stopAtEntry = true,
        --             },
        --         }
        --     end
        -- }
    }

    use {
        'nvimdev/lspsaga.nvim',
        requires = 'nvim-lspconfig',
        config = function()
            require('lspsaga').setup({
                code_action = {
                    keys = {
                        quit = {'<esc>', 'q'}
                    }
                },
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
                lightbulb = {
                    enable = true,
                    sign = false,
                    virtual_text = true,
                    enable_in_insert = false,
                },
                outline = {
                    auto_preview = false,
                    auto_close = true,
                    detail = true,
                    -- layout = 'float',
                    win_position = 'right',
                    win_width = 45,
                    keys = {
                        jump = '<cr>'
                    }
                },
                rename = {
                    keys = {
                        quit = '<esc>'
                    }
                }
            })
        end,
    }

    use {
        "ray-x/lsp_signature.nvim",
        config = function()
            local cfg = {
                hint_prefix = " ",
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
