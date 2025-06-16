return {
    settings = {
        Lua = {
            diagnostics = {
                globals = {
                    "vim",
                    "Snacks"
                },
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
