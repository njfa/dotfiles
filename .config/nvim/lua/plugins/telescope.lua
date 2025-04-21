-- ファジーファインダー
local vscode = require('vscode-utils')

return {
    {
        'nvim-telescope/telescope.nvim',
        branch = 'master',
        enabled = not vscode.is_vscode,
        dependencies = {
            'nvim-lua/plenary.nvim',
            'nvim-telescope/telescope-frecency.nvim',
            'nvim-telescope/telescope-ui-select.nvim',
            {
                'nvim-telescope/telescope-dap.nvim',
                dependencies = {
                    'mfussenegger/nvim-dap',
                }
            },
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
        },
        config = function()
            local actions = require("telescope.actions")
            require('telescope').setup {
                defaults = {
                    mappings = {
                        i = {
                            ["<esc>"] = actions.close,
                            ["<C-a>"] = actions.select_all
                        },

                    },
                    vimgrep_arguments = {
                        'rg',
                        '--no-heading',
                        '--with-filename',
                        '--line-number',
                        '--column',
                        '--smart-case',
                        '--hidden',
                        '--no-ignore',
                        '--trim',
                        "--glob",
                        "!**/.git/*"
                    },
                    file_ignore_patterns = {
                        "node_modules/",
                        "target/",
                        "**/.git/"
                    }
                },
                pickers = {
                    find_files = {
                        layout_strategy = "vertical",
                        layout_config = {
                            height = 0.99,
                            preview_cutoff = 40,
                            prompt_position = "bottom",
                            width = 0.99,
                            preview_height = 15,
                        },
                    },
                    oldfiles = {
                        layout_strategy = "vertical",
                        layout_config = {
                            height = 0.99,
                            preview_cutoff = 40,
                            prompt_position = "bottom",
                            width = 0.99,
                            preview_height = 15,
                        },
                    },
                    live_grep = {
                        layout_strategy = "vertical",
                        layout_config = {
                            height = 0.99,
                            preview_cutoff = 40,
                            prompt_position = "bottom",
                            width = 0.99
                        },
                    },
                    buffers = {
                        layout_strategy = "vertical",
                        layout_config = {
                            height = 0.99,
                            preview_cutoff = 40,
                            prompt_position = "bottom",
                            width = 0.99,
                            preview_height = 15,
                        },
                    },
                },
                extensions = {
                    frecency = {
                        show_scores = true,
                        ignore_patterns = { "**/.git/*" },
                        layout_strategy = "vertical",
                        layout_config = {
                            height = 0.99,
                            preview_cutoff = 40,
                            prompt_position = "bottom",
                            width = 0.99,
                            preview_height = 15,
                        },
                    },
                    ["ui-select"] = {
                        require("telescope.themes").get_dropdown {
                            layout_config = {
                                width = 100,
                            },
                            -- even more opts
                        }
                    },
                },
            }

            require('telescope').load_extension('dap')
            require('telescope').load_extension('projects')
            require('telescope').load_extension("frecency")
            require('telescope').load_extension("ui-select")
        end
    },
}
