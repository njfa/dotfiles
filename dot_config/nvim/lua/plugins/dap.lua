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

            -- Javaはアタッチ方式を基本とする。アプリ側をjdwp付きで起動しておき、
            -- ポート指定で接続する(アプリ系統ごとにポートを分ければ同時デバッグ可能)。
            -- リポジトリ固有の定義は.vscode/launch.jsonに書けばnvim-dapが自動で読み込む
            dap.configurations.java = {
                {
                    type = "java",
                    request = "attach",
                    name = "実行中のJVMにアタッチ (ポート指定)",
                    hostName = "localhost",
                    port = function()
                        return tonumber(vim.fn.input("デバッグポート: ", "5005"))
                    end,
                },
            }

            local widgets = require("dap.ui.widgets")
            vim.keymap.set("n", "<F4>", function()
                dap.set_breakpoint(vim.fn.input("ブレークポイント条件: "))
            end, { desc = "条件付きブレークポイントの追加" })
            vim.keymap.set("n", "<F5>", dap.toggle_breakpoint, { desc = "ブレークポイントの切替" })
            vim.keymap.set("n", "<F6>", dap.step_into, { desc = "ステップ実行 (IN)" })
            vim.keymap.set("n", "<F7>", dap.continue, { desc = "デバッグ開始/再開" })
            vim.keymap.set("n", "<F8>", dap.step_over, { desc = "ステップ実行 (OVER)" })
            vim.keymap.set("n", "<F9>", dap.step_out, { desc = "ステップ実行 (OUT)" })
            vim.keymap.set("n", "<F10>", widgets.sessions, { desc = "デバッグセッションの切替" })
            vim.keymap.set("n", "<F12>", dapui.toggle, { desc = "DAP UIの表示切替" })
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
