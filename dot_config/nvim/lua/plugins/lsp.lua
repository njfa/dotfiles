local vscode_enabled, _ = pcall(require, "vscode")

vim.lsp.config("*", {
    root_markers = { ".git" },
    capabilities = require("blink.cmp").get_lsp_capabilities(vim.lsp.protocol.make_client_capabilities()),
})

-- Server-specific on_attach callbacks must not hide the shared keymaps.
vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("dotfiles_lsp_attach", { clear = true }),
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if not client then
            return
        end
        if client.name == "ruff" then
            client.server_capabilities.hoverProvider = false
        end
        require("common").on_attach_lsp(client, args.buf)
    end,
})

-- jdtls is started by ftplugin/java.lua via nvim-jdtls.
-- Keep Neovim's built-in lspconfig path disabled to avoid duplicate clients.
vim.lsp.enable('jdtls', false)

return {
    {
        "rachartier/tiny-inline-diagnostic.nvim",
        event = "VeryLazy", -- Or `LspAttach`
        priority = 1000, -- needs to be loaded in first
        cond = not vscode_enabled,
        config = function()
            require("tiny-inline-diagnostic").setup({
                options = {
                    multilines = {
                        -- Enable multiline diagnostic messages
                        enabled = true,

                        -- Always show messages on all lines for multiline diagnostics
                        always_show = true,
                    },
                },
            })
            vim.diagnostic.config({
                virtual_text = false,
                -- error/warn/infoをソート
                severity_sort = true,

                -- 下線の設定
                underline = true,

                -- エラーと警告の下線スタイルを設定
                signs = {
                    text = {
                        [vim.diagnostic.severity.ERROR] = '',
                        [vim.diagnostic.severity.WARN] = '',
                        [vim.diagnostic.severity.HINT] = '',
                        [vim.diagnostic.severity.INFO] = '',
                    },
                    linehl = {
                        [vim.diagnostic.severity.ERROR] = '',
                        [vim.diagnostic.severity.WARN] = '',
                        [vim.diagnostic.severity.HINT] = '',
                        [vim.diagnostic.severity.INFO] = '',
                    },
                    numhl = {
                        [vim.diagnostic.severity.ERROR] = 'DiagnosticSignError',
                        [vim.diagnostic.severity.WARN] = 'DiagnosticSignWarn',
                        [vim.diagnostic.severity.HINT] = 'DiagnosticSignHint',
                        [vim.diagnostic.severity.INFO] = 'DiagnosticSignInfo',
                    },
                },
            }) -- Only if needed in your configuration, if you already have native LSP diagnostics
        end,
    },

    {
        "mfussenegger/nvim-jdtls",
        dependencies = { "mfussenegger/nvim-dap" },
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
                            package_uninstalled = "✗",
                        },
                    },
                },
            },
            "neovim/nvim-lspconfig",
        },
        config = function()
            require("mason-lspconfig").setup({
                automatic_enable = {
                    exclude = {
                        "jdtls",
                        "pylsp", -- Replaced by Pyright; may still be installed in Mason.
                    },
                },
                ensure_installed = {
                    -- "rust_analyzer",
                    "ts_ls",
                    "lua_ls",
                    "ruff",
                    "pyright",
                    "gopls",
                    "tflint",
                    "terraformls",
                    "jdtls",
                },
            })
        end,
    },

    -- masonとnone-lsの連携
    {
        "jay-babu/mason-null-ls.nvim",
        cond = not vscode_enabled,
        dependencies = {
            "mason-org/mason.nvim",
            "nvimtools/none-ls.nvim",
        },
        config = function()
            local null_ls = require("null-ls")

            local null_sources = {
                -- null_ls.builtins.diagnostics.markdownlint.with({
                --     extra_args = { "--disable", "MD007", "MD012", "MD013" }
                -- })
            }

            require("mason-null-ls").setup({
                ensure_installed = {
                    "markdown",
                    "markdownlint",
                    "openjdk-21",
                    "lombok-nightly",
                    "java-debug-adapter",
                    "java-test",
                    "debugpy",
                    "delve",
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
                            extra_args = { "--disable", "MD007", "MD012", "MD013", "MD033", "MD051", "MD038", "MD040" },
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
                    auto_jump = false,
                    auto_preview = false,
                    -- some modes are configurable, see the source code for more details
                    params = {
                        include_declaration = true,
                    },
                    win = {
                        position = "right",
                        size = 0.3,
                    },
                },
                lsp_definitions = {
                    auto_jump = false,
                    auto_preview = false,
                },
                lsp_implementations = {
                    auto_jump = false,
                    auto_preview = false,
                },
                -- The LSP base mode for:
                -- * lsp_definitions, lsp_references, lsp_implementations
                -- * lsp_type_definitions, lsp_declarations, lsp_command
                lsp_base = {
                    auto_jump = false,
                    auto_preview = false,
                    params = {
                        -- don't include the current location in the results
                        include_current = false,
                    },
                    win = {
                        position = "right",
                        size = 0.3,
                    },
                },
                lsp = {
                    mode = "lsp",
                    sections = {
                        "lsp_definitions",
                        "lsp_references",
                        "lsp_implementations",
                    },
                    auto_jump = false,
                    auto_preview = false,
                    win = {
                        position = "right",
                        size = 0.3,
                    },
                },
            },
        }, -- for default options, refer to the configuration section for custom setup.
        cmd = "Trouble",
        keys = {},
    },
}
