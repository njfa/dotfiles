-- キーバインドをわかりやすくする
return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function ()
        -- which-key.nvimの表示間隔を狭める
        vim.opt.timeout = true
        vim.opt.timeoutlen = 200
    end,
    config = function()
        local wk = require("which-key")
        wk.register({
            ["<leader>"] = {
                f = { "<Cmd>lua require('picker').find_files_from_project_git_root()<CR>", "Telescope find_files" },
                F = { ":lua require('picker').find_files_from_project_git_root( { search_file=\"\" })<left><left><left><left>", "Telescope find_files search_file=<input>"},
                g = { "<Cmd>lua require('picker').live_grep_from_project_git_root()<CR>", "Telescope live_grep"},
                G = { ":lua require('picker').live_grep_from_project_git_root( { glob_pattern=\"\" })<left><left><left><left>", "Telescope live_grep search_file=<input>"},
                h = { "<Cmd>lua require('telescope').extensions.frecency.frecency()<CR>", "Telescope frecency"},
                H = { "<Cmd>lua require('picker').find_files_from_project_git_root({oldfiles=true})<CR>", "Telescope project_files"},
                c = { '<cmd>enew<cr>', "New Buffer" },
                C = { '<cmd>tabnew<cr>', "New Tab" },
                d = { "<cmd>bp<bar>sp<bar>bn<bar>bd!<cr>", "Close buffer" },
                D = { "<Cmd>tabclose<CR>", "Close Tab" },

                -- map("x", "<leader>f", "<Cmd>lua require('picker').find_files_string_visual()<CR>")
                -- map("x", "<leader>g", "<Cmd>lua require('picker').grep_string_visual()<CR>")
            }
        }, {
            mode = "n"
        })

        wk.register({
            ["<leader>"] = {
                f = { "<Cmd>lua require('picker').find_files_string_visual()<CR>", "Telescope find_files" },
                g = { "<Cmd>lua require('picker').grep_string_visual()<CR>", "Telescope live_grep"},
            }
        }, {
            mode = "x"
        })
        -- wk.setup {
            --     -- your configuration comes here
            --     -- or leave it empty to the default settings
            --     -- refer to the configuration section below
            -- }
        end
    }
