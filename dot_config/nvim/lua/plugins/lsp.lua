local vscode_enabled, _ = pcall(require, "vscode")

local function filter_jdt_uri_items(items)
    return vim.tbl_filter(function(item)
        return not (type(item.filename) == "string" and vim.startswith(item.filename, "jdt://"))
    end, items)
end

vim.lsp.config("*", {
    root_markers = { ".git" },
    on_attach = function(_, bufnr)
        require("common").on_attach_lsp(_, bufnr)
    end,
    capabilities = require("blink.cmp").get_lsp_capabilities(vim.lsp.protocol.make_client_capabilities()),
})

-- jdtls is started by ftplugin/java.lua via nvim-jdtls.
-- Keep Neovim's built-in lspconfig path disabled to avoid duplicate clients.
vim.lsp.enable('jdtls', false)

return {
    -- 色定義の追加
    {
        "folke/lsp-colors.nvim",
        cond = not vscode_enabled,
    },
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
                    },
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
                },
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
                    filter = filter_jdt_uri_items,
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
                    filter = filter_jdt_uri_items,
                },
                lsp_implementations = {
                    auto_jump = false,
                    auto_preview = false,
                    filter = filter_jdt_uri_items,
                },
                lsp_type_definitions = {
                    auto_jump = false,
                    auto_preview = false,
                    filter = filter_jdt_uri_items,
                },
                lsp_declarations = {
                    auto_jump = false,
                    auto_preview = false,
                    filter = filter_jdt_uri_items,
                },
                lsp_incoming_calls = {
                    auto_preview = false,
                    filter = filter_jdt_uri_items,
                },
                lsp_outgoing_calls = {
                    auto_preview = false,
                    filter = filter_jdt_uri_items,
                },
                -- The LSP base mode for:
                -- * lsp_definitions, lsp_references, lsp_implementations
                -- * lsp_type_definitions, lsp_declarations, lsp_command
                lsp_base = {
                    auto_jump = false,
                    auto_preview = false,
                    filter = filter_jdt_uri_items,
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
                    filter = filter_jdt_uri_items,
                    win = {
                        position = "right",
                        size = 0.3,
                    },
                },
            },
        }, -- for default options, refer to the configuration section for custom setup.
        cmd = "Trouble",
        keys = {},
        config = function(_, opts)
            local lsp = require("trouble.sources.lsp")
            local locations_to_ranges = lsp._dotfiles_locations_to_ranges or lsp.locations_to_ranges
            lsp._dotfiles_locations_to_ranges = locations_to_ranges

            lsp.locations_to_ranges = function(client, locs)
                local normal_locs = {}
                local jdt_locs = {}

                for _, loc in ipairs(locs) do
                    local uri = loc.uri or loc.targetUri
                    if type(uri) == "string" and vim.startswith(uri, "jdt://") then
                        table.insert(jdt_locs, loc)
                    else
                        table.insert(normal_locs, loc)
                    end
                end

                local ret = locations_to_ranges(client, normal_locs)
                for _, loc in ipairs(jdt_locs) do
                    local uri = loc.uri or loc.targetUri
                    local range = loc.range or loc.targetSelectionRange
                    ret[loc] = {
                        filename = uri,
                        pos = { range.start.line + 1, range.start.character },
                        end_pos = { range["end"].line + 1, range["end"].character },
                        source = "lsp",
                        client = client,
                        location = loc,
                        line = "",
                    }
                end

                return ret
            end

            require("trouble").setup(opts)
        end,
    },
}
