-- ファジーファインダー
return {
    -- telescopeでプロジェクトの一覧を表示するのに利用する
    {
        "ahmedkhalf/project.nvim",
        config = function()
            require("project_nvim").setup {
                -- Methods of detecting the root directory. **"lsp"** uses the native neovim
                -- lsp, while **"pattern"** uses vim-rooter like glob pattern matching. Here
                -- order matters: if one is not detected, the other is used as fallback. You
                -- can also delete or rearangne the detection methods.
                detection_methods = { "pattern", "lsp" },

                -- All the patterns used to detect root dir, when **"pattern"** is in
                -- detection_methods
                patterns = { ".git", "_darcs", ".hg", ".bzr", ".svn", "Makefile", "package.json", ".env", ".gitlab-ci.yml" },

                scope_chdir = 'tab',

                datapath = vim.fn.stdpath("data")
            }
        end
    },

    {
        'nvim-telescope/telescope-dap.nvim',
        dependencies = {
            'mfussenegger/nvim-dap',
        }
    },

    {
        "nvim-telescope/telescope-frecency.nvim"
    },

    {
        'nvim-telescope/telescope.nvim',
        branch = 'master',
        dependencies = {
            'nvim-lua/plenary.nvim',
            'nvim-telescope/telescope-frecency.nvim',
            'nvim-telescope/telescope-dap.nvim',
            "ahmedkhalf/project.nvim",
        },
        config = function()
            local actions = require("telescope.actions")
            require('telescope').setup {
                defaults = {
                    layout_strategy = "vertical",
                    layout_config = {
                        horizontal = {
                            height = 0.99,
                            preview_cutoff = 40,
                            prompt_position = "bottom",
                            width = 0.99
                        },
                        vertical = {
                            height = 0.99,
                            preview_cutoff = 40,
                            prompt_position = "bottom",
                            width = 0.99
                        }
                    },
                    mappings = {
                        i = {
                            ["<esc>"] = actions.close
                        },

                    },
                    vimgrep_arguments = {
                        'rg',
                        '--with-filename',
                        '--line-number',
                        '--column',
                        '--smart-case',
                        '--no-ignore',
                        '--hidden',
                        '--trim'
                    },
                    file_ignore_patterns = {
                        "node_modules",
                        ".git",
                        "target"
                    }
                },
                extensions = {
                    frecency = {
                        db_root = vim.fn.stdpath("data"),
                        show_scores = true,
                        ignore_patterns = { "*.git/*", "*/tmp/*" },
                    }
                },
            }

            require('telescope').load_extension('dap')
            require('telescope').load_extension('projects')
            require('telescope').load_extension("frecency")
        end
    },
}
