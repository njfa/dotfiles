if vim.fn.search("^\t", "nw") == 0 then
    vim.opt_local.expandtab = true
else
    vim.opt_local.expandtab = false
end
