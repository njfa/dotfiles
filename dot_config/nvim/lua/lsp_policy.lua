return {
    -- Managed servers are installed by Mason, but are disabled unless opted in below.
    servers = {
        "ts_ls",
        "lua_ls",
        "ruff",
        "pyright",
        "gopls",
        "tflint",
        "terraformls",
        "jdtls",
    },
    -- Automatically enable only these servers on startup. Example: { "lua_ls", "ruff" }.
    -- "jdtls" and "null-ls" (CLI diagnostics via none-ls) are also supported.
    default_enabled = {},
}
