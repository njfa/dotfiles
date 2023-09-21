local M = {}

function M.load(use)
    use {
        'preservim/vim-markdown',
        ft = {'txt', 'markdown'},
        requires = {
            'godlygeek/tabular'
        },
        config =function ()
            vim.g.vim_markdown_folding_disabled = 1
            vim.g.vim_markdown_no_default_key_mappings = 1
            vim.g.vim_markdown_toc_autofit = 1
            vim.g.vim_markdown_new_list_item_indent = 0
        end
    }

    -- plugins.luaに移動
    -- use {
    --     "iamcco/markdown-preview.nvim",
    --     run = "cd app && npm install",
    --     setup = function() vim.g.mkdp_filetypes = { "markdown", "plantuml" } end,
    --     ft = { "markdown", "plantuml" },
    -- }
end

return M;
