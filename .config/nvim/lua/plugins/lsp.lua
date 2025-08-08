local vscode_enabled, _ = pcall(require, "vscode")

vim.lsp.config('*', {
    root_markers = { '.git' },
    on_attach = function(_, bufnr)
        require("common").on_attach_lsp(_, bufnr)
    end,
    capabilities = require('blink.cmp').get_lsp_capabilities(vim.lsp.protocol.make_client_capabilities()),
})

-- vim.lsp.enable('jdtls', false)

return {
    -- 色定義の追加
    {
        "folke/lsp-colors.nvim",
        cond = not vscode_enabled,
    },
    {
        "rachartier/tiny-inline-diagnostic.nvim",
        event = "VeryLazy", -- Or `LspAttach`
        priority = 1000,    -- needs to be loaded in first
        cond = not vscode_enabled,
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

    {
        "mfussenegger/nvim-jdtls",
        ft = { "java" },
        lazy = false,
        priority = 999,
    },
    -- LSPサーバー管理
    {
        "mason-org/mason-lspconfig.nvim",
        dependencies = {
            {
                "mason-org/mason.nvim",
                opts = {
                    registries = {
                        "file:" .. vim.fn.stdpath("config") .. "/lua/mason-custom-registry",
                        "github:mason-org/mason-registry",
                    },
                    ui = {
                        icons = {
                            package_installed = "✓",
                            package_pending = "➜",
                            package_uninstalled = "✗"
                        }
                    }
                }
            },
            "neovim/nvim-lspconfig",
        },
        config = function()
            require("mason-lspconfig").setup({
                automatic_enable = {
                    exclude = {
                        "jdtls",
                    }
                },
                ensure_installed = {
                    -- "rust_analyzer",
                    "ts_ls",
                    "lua_ls",
                    "ruff",
                    "pylsp",
                    "tflint",
                    "terraformls",
                    "jdtls",
                }
            })
        end
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
                    "markdown",
                    "markdownlint",
                    "openjdk-21",
                    "lombok-nightly",
                    "google-java-format",
                    "prettier",
                    "stylua",
                    "shfmt",
                },
                automatic_installation = false,
                handlers = {
                    -- function() end, -- disables automatic setup of all null-ls sources
                    markdownlint = function(_, _)
                        null_ls.register(null_ls.builtins.diagnostics.markdownlint.with({
                            extra_args = { "--disable", "MD007", "MD012", "MD013", "MD033", "MD051", "MD038" },
                        }))
                    end,
                    shfmt = function(source_name, methods)
                        null_ls.register(null_ls.builtins.formatting.shfmt.with({
                            extra_args = { "-i", "4" }, -- インデントをスペース4つに設定
                        }))
                    end,
                },
            })

            null_ls.setup({
                debug = true,
                sources = null_sources,
            })
        end,
    },

    -- LSPの結果を一覧表示
    {
        "folke/trouble.nvim",
        cond = not vscode_enabled,
        opts = {
            modes = {
                lsp_references = {
                    -- some modes are configurable, see the source code for more details
                    params = {
                        include_declaration = true,
                    },
                    win = {
                        position = "right",
                        size = 0.3,
                    }
                },
                -- The LSP base mode for:
                -- * lsp_definitions, lsp_references, lsp_implementations
                -- * lsp_type_definitions, lsp_declarations, lsp_command
                lsp_base = {
                    params = {
                        -- don't include the current location in the results
                        include_current = false,
                    },
                    win = {
                        position = "right",
                        size = 0.3,
                    }
                },
                lsp = {
                    mode = "lsp",
                    win = {
                        position = "right",
                        size = 0.3,
                    }
                },
            },
        }, -- for default options, refer to the configuration section for custom setup.
        cmd = "Trouble",
        keys = {},
    },
}
