local vscode_enabled, _ = pcall(require, "vscode")

return {
    -- 色定義の追加
    "folke/lsp-colors.nvim",
    cond = not vscode_enabled,

    -- LSPの結果を別行に表示する
    -- {
    --     "https://git.sr.ht/~whynothugo/lsp_lines.nvim",
    --     cond = not vscode_enabled,
    --     config = function()
    --         vim.diagnostic.config({
    --             virtual_text = false,

    --             -- error/warn/infoをソート
    --             severity_sort = true,

    --             -- 下線の設定
    --             underline = true,

    --             -- エラーと警告の下線スタイルを設定
    --             signs = true,
    --         })

    --         require("lsp_lines").setup()
    --     end,
    -- },
    {
        "rachartier/tiny-inline-diagnostic.nvim",
        event = "VeryLazy", -- Or `LspAttach`
        priority = 1000,    -- needs to be loaded in first
        config = function()
            require('tiny-inline-diagnostic').setup({
                options = {
                    multilines = {
                        -- Enable multiline diagnostic messages
                        enabled = true,

                        -- Always show messages on all lines for multiline diagnostics
                        always_show = true,
                    },
                }
            })
            vim.diagnostic.config({
                virtual_text = false,
                -- error/warn/infoをソート
                severity_sort = true,

                -- 下線の設定
                underline = true,

                -- エラーと警告の下線スタイルを設定
                signs = true,
            }) -- Only if needed in your configuration, if you already have native LSP diagnostics
        end
    },
    -- LSPサーバー管理
    {
        "williamboman/mason-lspconfig.nvim",
        cond = not vscode_enabled,
        branch = "v1.x",
        dependencies = {
            "neovim/nvim-lspconfig",
            "hrsh7th/cmp-nvim-lsp",
            "simrat39/rust-tools.nvim",
            "nvimtools/none-ls.nvim",
            "mfussenegger/nvim-jdtls",
            {
                "williamboman/mason.nvim",
                opts = {
                    registries = {
                        "file:" .. vim.fn.stdpath("config") .. "/lua/mason-custom-registry",
                        "github:mason-org/mason-registry",
                    },
                },
            },
            {
                "nvimdev/lspsaga.nvim",
                dependencies = {
                    "neovim/nvim-lspconfig",
                },
                config = function()
                    require("lspsaga").setup({
                        code_action = {
                            keys = {
                                quit = { "<esc>", "q" },
                            },
                        },
                        finder = {
                            max_height = 0.6,
                            keys = {
                                edit = "o",
                                vsplit = "e",
                                toggle_or_open = "<cr>",
                                shuttle = "<C-w>",
                            },
                            methods = {
                                tyd = "textDocument/typeDefinition",
                            },
                            default = "def+ref+imp+tyd",
                        },
                        callhierarchy = {
                            keys = {
                                edit = "o",
                                vsplit = "e",
                                toggle_or_open = "<cr>",
                                shuttle = "<C-w>",
                            },
                        },
                        hover = {
                            open_cmd = "!browser.sh",
                        },
                        lightbulb = {
                            enable = true,
                            sign = false,
                            virtual_text = false,
                            enable_in_insert = false,
                        },
                        outline = {
                            auto_preview = false,
                            auto_close = true,
                            detail = true,
                            -- layout = 'float',
                            win_position = "right",
                            win_width = 45,
                            keys = {
                                jump = "<cr>",
                            },
                        },
                        rename = {
                            keys = {
                                quit = "<esc>",
                            },
                        },
                    })
                end,
            },
        },
        config = function()
            -- mason
            require("mason").setup({
                ui = {
                    icons = {
                        package_installed = "✓",
                        package_pending = "➜",
                        package_uninstalled = "-",
                    },
                },
            })
            require("mason-lspconfig").setup()
            require("mason-lspconfig").setup_handlers({
                function(server_name)
                    -- Setup lspconfig.
                    require("lspconfig")[server_name].setup({
                        on_attach = function(_, bufnr)
                            require("common").on_attach_lsp(_, bufnr, server_name)
                        end,
                        capabilities = require('blink.cmp').get_lsp_capabilities(vim.lsp.protocol
                            .make_client_capabilities())
                        -- capabilities = require("cmp_nvim_lsp").default_capabilities(
                        --     vim.lsp.protocol.make_client_capabilities()
                        -- ),
                    })
                end,

                ["lua_ls"] = function()
                    require("lspconfig").lua_ls.setup({
                        settings = {
                            Lua = {
                                diagnostics = {
                                    globals = { "vim" },
                                },
                            },
                        },
                        on_attach = function(_, bufnr)
                            require("common").on_attach_lsp(_, bufnr, "lua_ls")
                        end,
                        capabilities = require('blink.cmp').get_lsp_capabilities(vim.lsp.protocol
                            .make_client_capabilities())
                        -- capabilities = require("cmp_nvim_lsp").default_capabilities(
                        --     vim.lsp.protocol.make_client_capabilities()
                        -- ),
                    })
                end,

                ["jdtls"] = function()
                end,

                ["rust_analyzer"] = function()
                    -- local codelldb_path = require("mason-registry").get_package("codelldb"):get_install_path() .. "/extension"
                    local codelldb_path = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension"
                    local codelldb_bin = codelldb_path .. "/adapter/codelldb"
                    local liblldb_bin = codelldb_path .. "/lldb/lib/liblldb.so"

                    local rt = require("rust-tools")

                    local cfg = {
                        server = {
                            settings = {
                                ["rust-analyzer"] = {
                                    cargo = {
                                        autoReload = true,
                                    },
                                },
                            },
                        },
                        dap = {
                            adapter = require("rust-tools.dap").get_codelldb_adapter(codelldb_bin, liblldb_bin),
                        },
                    }

                    rt.setup(cfg)

                    -- require('dap.ext.vscode').load_launchjs(nil, {rt_lldb={'rust'}})
                    require("dap").configurations.rust = {
                        {
                            type = "rt_lldb",
                            request = "launch",
                            name = "Debug (Attach)",
                            cwd = "${workspaceFolder}",
                            program = "${workspaceFolder}/target/debug/${workspaceFolderBasename}",
                            stopAtEntry = true,
                        },
                    }
                end,

                ["ruff"] = function()
                    require('lspconfig').ruff.setup {
                        init_options = {
                            configuration = "~/.ruff.toml"
                        }
                    }
                end,

                ["pylsp"] = function()
                    require("lspconfig").pylsp.setup({
                        settings = {
                            pylsp = {
                                plugins = {
                                    -- formatter options
                                    black = { enabled = false },
                                    autopep8 = { enabled = false },
                                    yapf = { enabled = false },
                                    -- linter options
                                    pylint = { enabled = false, },
                                    pyflakes = { enabled = false },
                                    pycodestyle = { enabled = false },
                                    -- type checker
                                    pylsp_mypy = { enabled = true },
                                    -- auto-completion options
                                    jedi_completion = { fuzzy = true },
                                    -- import sorting
                                    pyls_isort = { enabled = false },
                                },
                            },
                        },
                        on_attach = function(_, bufnr)
                            require("common").on_attach_lsp(_, bufnr, "pylsp")
                        end,
                        capabilities = require('blink.cmp').get_lsp_capabilities(vim.lsp.protocol
                            .make_client_capabilities())
                        -- capabilities = require("cmp_nvim_lsp").default_capabilities(
                        --     vim.lsp.protocol.make_client_capabilities()
                        -- ),
                    })
                end,
            })
        end,
    },

    -- masonとnone-lsの連携
    {
        "jay-babu/mason-null-ls.nvim",
        cond = not vscode_enabled,
        dependencies = {
            "williamboman/mason.nvim",
            "nvimtools/none-ls.nvim",
        },
        config = function()
            local null_ls = require("null-ls")

            local null_sources = {
                -- null_ls.builtins.diagnostics.markdownlint.with({
                --     extra_args = { "--disable", "MD007", "MD012", "MD013" }
                -- })
            }

            -- for _, package in ipairs(mason_registry.get_installed_packages()) do
            --     local package_categories = package.spec.categories[1]
            --     if package_categories == mason_package.Cat.Formatter then
            --         table.insert(null_sources, null_ls.builtins.formatting[package.name])
            --     end
            --     if package_categories == mason_package.Cat.Linter then
            --         table.insert(null_sources, null_ls.builtins.diagnostics[package.name])
            --     end
            -- end

            require("mason-null-ls").setup({
                ensure_installed = {
                    -- markdown
                    "markdown",
                    "markdownlint",
                    -- java
                    "openjdk-21",
                    "jdtls",
                    "lombok-nightly",
                    "google-java-format",
                    -- python
                    "python-lsp-server",
                    -- "pylint",
                    -- "isort",
                    -- "black",
                    "ruff",
                    -- terraform
                    "terraform-ls",
                    "tflint",
                    -- javascript
                    "prettier",
                    -- lua
                    "stylua",
                    -- bash
                    "shfmt",
                },
                automatic_installation = false,
                handlers = {
                    function() end, -- disables automatic setup of all null-ls sources
                    markdownlint = function(_, _)
                        null_ls.register(null_ls.builtins.diagnostics.markdownlint.with({
                            extra_args = { "--disable", "MD007", "MD012", "MD013", "MD033", "MD051", "MD038" },
                        }))
                    end,
                    -- shfmt = function(source_name, methods)
                    --     -- custom logic
                    --     require('mason-null-ls').default_setup(source_name, methods) -- to maintain default behavior
                    -- end,
                },
            })

            null_ls.setup({
                debug = true,
                sources = null_sources,
            })
        end,
    },

    -- {
    --     "ray-x/lsp_signature.nvim",
    --     event = "VeryLazy",
    --     opts = {},
    --     config = function(_, opts)
    --         opts.bind = true
    --         opts.handler_opts = {
    --             border = "rounded",
    --         }
    --         opts.hint_prefix = "󱄑 "
    --         -- opts.hint_prefix = " "
    --         opts.transparency = 10
    --         opts.max_width = 120
    --         opts.floating_window_off_x = function()             -- adjust float windows x position.
    --             local colnr = vim.api.nvim_win_get_cursor(0)[2] -- buf col number
    --             return colnr
    --             -- return vim.fn.wincol()
    --         end
    --         opts.floating_window_off_y = function() -- adjust float windows y position. e.g. set to -2 can make floating window move up 2 lines
    --             -- local linenr = vim.api.nvim_win_get_cursor(0)[1] -- buf line number
    --             local pumheight = vim.o.pumheight
    --             local winline = vim.fn.winline() -- line number in the window
    --             local winheight = vim.fn.winheight(0)

    --             -- window top
    --             if winline - 1 < pumheight then
    --                 return pumheight
    --             end

    --             -- window bottom
    --             if winheight - winline < pumheight then
    --                 return -pumheight
    --             end
    --             return 0
    --         end

    --         require("lsp_signature").setup(opts)
    --     end,
    -- },

    -- LSPの結果を一覧表示
    {
        "folke/trouble.nvim",
        cond = not vscode_enabled,
        opts = {}, -- for default options, refer to the configuration section for custom setup.
        cmd = "Trouble",
        keys = {},
    },

    -- {
    --     'nvim-java/nvim-java',
    --     dependencies = {
    --         'nvim-java/lua-async-await',
    --         'nvim-java/nvim-java-refactor',
    --         'nvim-java/nvim-java-core',
    --         'nvim-java/nvim-java-test',
    --         'nvim-java/nvim-java-dap',
    --         'MunifTanjim/nui.nvim',
    --         'neovim/nvim-lspconfig',
    --         'mfussenegger/nvim-dap',
    --         'williamboman/mason.nvim',
    --     },
    -- }
}
