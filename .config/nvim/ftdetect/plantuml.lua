vim.api.nvim_create_autocmd({"BufNewFile", "BufRead"}, {
    pattern = { "*.pu" },
    callback = function()
        vim.api.nvim_exec('set filetype=plantuml', false)
    end,
})

