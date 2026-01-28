-- 共通の前提部分を定義
return {
    {
        "zbirenbaum/copilot.lua",
        cmd = "Copilot",
        event = "InsertEnter",
        enabled = vim.g.llm_enabled,
        config = function()
            require("copilot").setup({
                suggestion = { enabled = false },
                panel = { enabled = false },
                copilot_node_command = "node",
            })
        end,
    },
    {
        "folke/sidekick.nvim",
        opts = {
            -- add any options here
            nes = {
                enabled = false
            },
            cli = {
                mux = {
                    backend = "tmux",
                    enabled = true,
                    create = "split",
                },
            },
            copilot = {
                -- track copilot's status with `didChangeStatus`
                status = {
                    enabled = false
                },
            },
            tools = {
                claude = { cmd = { "claude" } },
                codex = { cmd = { "codex" } },
                copilot = { cmd = { "copilot", "--banner" } },
                gemini = { cmd = { "gemini" } },
            },
        },
        keys = {
            {
                ",a",
                function()
                    require("sidekick.cli").toggle()
                end,
                desc = "Sidekick Toggle CLI",
            },
            {
                ",s",
                function()
                    require("sidekick.cli").select()
                end,
                -- Or to select only installed tools:
                -- require("sidekick.cli").select({ filter = { installed = true } })
                desc = "Select CLI",
            },
            {
                ",d",
                function()
                    require("sidekick.cli").close()
                end,
                desc = "Detach a CLI Session",
            },
            {
                ",t",
                function()
                    require("sidekick.cli").send({ msg = "{this}" })
                end,
                mode = { "x", "n" },
                desc = "Send This",
            },
            {
                ",f",
                function()
                    require("sidekick.cli").send({ msg = "{file}" })
                end,
                desc = "Send File",
            },
            {
                ",v",
                function()
                    require("sidekick.cli").send({ msg = "````\n{selection}\n````" })
                end,
                mode = { "x" },
                desc = "Send Visual Selection",
            },
            {
                ",p",
                function()
                    require("sidekick.cli").prompt()
                end,
                mode = { "n", "x" },
                desc = "Sidekick Select Prompt",
            },
            {
                ",x",
                function()
                    require("sidekick.cli").toggle({ name = "codex", focus = true })
                end,
                desc = "Sidekick Toggle Codex",
            },
            {
                ",g",
                function()
                    require("sidekick.cli").toggle({ name = "gemini", focus = true })
                end,
                desc = "Sidekick Toggle Gemini",
            },
            {
                ",c",
                function()
                    require("sidekick.cli").toggle({ name = "claude", focus = true })
                end,
                desc = "Sidekick Toggle Claude",
            },
        },
    },
}
