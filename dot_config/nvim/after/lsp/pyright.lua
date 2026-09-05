return {
    settings = {
        pyright = {
            disableOrganizeImports = true, -- Ruff owns import organization.
        },
        python = {
            analysis = {
                typeCheckingMode = "basic",
                diagnosticMode = "openFilesOnly",
            },
        },
    },
}
