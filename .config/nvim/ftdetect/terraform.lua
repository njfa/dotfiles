vim.api.nvim_create_autocmd({"BufNewFile", "BufRead"}, {
    pattern = { "*.tf", "*.tfvars" },
    callback = function()
        vim.api.nvim_exec('set filetype=terraform', false)
    end,
})

