local M = {}

function M.load(use)
    -- 自動補完
    use {
        'hrsh7th/nvim-cmp',
        requires = {
            'neovim/nvim-lspconfig',
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-path',
            'hrsh7th/cmp-cmdline',
            'L3MON4D3/LuaSnip',
            'saadparwaiz1/cmp_luasnip',
            'hrsh7th/cmp-nvim-lsp-document-symbol',
            'hrsh7th/cmp-nvim-lsp-signature-help',
            'petertriho/cmp-git',
            'onsails/lspkind.nvim'
        },
        config = function()
            local mod = require('plugins/nvim-cmp')
            mod.load()
        end
    }
    use {
        'tzachar/cmp-tabnine',
        run='./install.sh',
        requires = 'hrsh7th/nvim-cmp',
        config = function()
            require('cmp_tabnine.config').setup({
                max_lines = 1000,
                max_num_results = 20,
                sort = true,
                run_on_every_keystroke = true,
                snippet_placeholder = '..',
                ignored_file_types = {
                    -- default is not to ignore
                    -- uncomment to ignore in lua:
                    -- lua = true
                },
                show_prediction_strength = false
            })
        end
    }
end

return M;

