local M = {}

function M.load(use)
    use 'mfussenegger/nvim-dap'

    use {
        "rcarriga/nvim-dap-ui",
        requires = {"mfussenegger/nvim-dap"},
        config = function()
            require("dapui").setup()

            local dap, dapui = require("dap"), require("dapui")
            dap.listeners.after.event_initialized["dapui_config"] = function()
                dapui.open()
            end
            dap.listeners.before.event_terminated["dapui_config"] = function()
                dapui.close()
            end
            dap.listeners.before.event_exited["dapui_config"] = function()
                dapui.close()
            end
        end
    }

    use {
        'theHamsta/nvim-dap-virtual-text',
        requires = {"mfussenegger/nvim-dap"},
        config = function()
            require("nvim-dap-virtual-text").setup()
        end
    }


    use {
        "folke/neodev.nvim",
        config = function()
            require("neodev").setup({
                library = { plugins = { "nvim-dap-ui" }, types = true },
            })
        end
    }
end

return M;
