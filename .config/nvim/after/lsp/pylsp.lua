return {
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
        require("common").on_attach_lsp(_, bufnr)
    end,
    capabilities = require('blink.cmp').get_lsp_capabilities(vim.lsp.protocol
        .make_client_capabilities())
    -- capabilities = require("cmp_nvim_lsp").default_capabilities(
    --     vim.lsp.protocol.make_client_capabilities()
    -- ),
}
