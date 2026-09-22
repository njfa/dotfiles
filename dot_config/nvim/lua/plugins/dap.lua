return {
    {
        "rcarriga/nvim-dap-ui",
        dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
        config = function()
            require("dapui").setup()

            local dap, dapui = require("dap"), require("dapui")
            dap.listeners.before.attach.dapui_config = function()
                dapui.open()
            end
            dap.listeners.before.launch.dapui_config = function()
                dapui.open()
            end
            -- dap.listeners.before.event_terminated.dapui_config = function()
            --     dapui.close()
            -- end
            -- dap.listeners.before.event_exited.dapui_config = function()
            --     dapui.close()
            -- end

            require("debugging").setup()

            vim.keymap.set("n", "<leader>vq", dap.terminate, { desc = "デバッグ終了" })
            local widgets = require("dap.ui.widgets")
            vim.keymap.set("n", "<leader>vB", function()
                dap.set_breakpoint(vim.fn.input("ブレークポイント条件: "))
            end, { desc = "条件付きブレークポイントの追加" })
            vim.keymap.set("n", "<leader>vb", dap.toggle_breakpoint, { desc = "ブレークポイントの切替" })
            vim.keymap.set("n", "<leader>vi", dap.step_into, { desc = "ステップ実行 (IN)" })
            vim.keymap.set("n", "<leader>vc", dap.continue, { desc = "デバッグ開始/再開" })
            vim.keymap.set("n", "<leader>vn", dap.step_over, { desc = "ステップ実行 (OVER)" })
            vim.keymap.set("n", "<leader>vo", dap.step_out, { desc = "ステップ実行 (OUT)" })
            vim.keymap.set("n", "<leader>vs", function()
                widgets.centered_float(widgets.sessions)
            end, { desc = "デバッグセッションの切替" })
            vim.keymap.set("n", "<leader>vu", dapui.toggle, { desc = "DAP UIの表示切替" })
        end,
    },

    {
        "theHamsta/nvim-dap-virtual-text",
        dependencies = { "mfussenegger/nvim-dap" },
        config = function()
            require("nvim-dap-virtual-text").setup()
        end,
    },
}
