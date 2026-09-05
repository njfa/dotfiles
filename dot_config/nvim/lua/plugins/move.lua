local camel_case_pattern = [[\%(\%(\u\l\+\)\|\%(\u\+\ze\u\l\)\|\%(\u\+\)\|\%(\l\+\)\|\%(#\x\+\>\)\|\%(\<0[xX]\x\+\>\)\|\%(\<0[oO][0-7]\+\>\)\|\%(\<0[bB][01]\+\>\)\|\%(\d\+\)\|\%(\~\)\|\%(!\)\|\%(@\)\|\%(#\)\|\%($\)\)]]

local function jump_to_pattern(pattern, end_position)
    require("flash").jump({
        pattern = pattern,
        search = { mode = "search", max_length = 0 },
        jump = { pos = end_position and "end" or "start" },
        label = end_position and { before = false, after = { 0, 0 } } or { before = { 0, 0 }, after = false },
    })
end

local function paste_at_target()
    require("flash").jump({
        action = function(match, state)
            state:hide()
            vim.api.nvim_win_call(match.win, function()
                vim.api.nvim_win_set_cursor(match.win, match.end_pos)
                vim.cmd([[normal! "*p]])
            end)
            state:restore()
        end,
    })
end

return {
    {
        "folke/flash.nvim",
        event = "VeryLazy",
        config = function()
            require("flash").setup({
                labels = "asdfghjklwertyuioxcvbnm,.",
                label = {
                    uppercase = true,
                },
                modes = {
                    char = {
                        keys = { "f", "F" },
                    },
                },
            })
        end,
        keys = {
            {
                ")",
                mode = { "n", "x", "o" },
                function()
                    jump_to_pattern([[^\s*\zs\S]], false)
                end,
                desc = "任意の行頭へ移動（空行は無視）",
            },
            {
                "t",
                mode = { "n", "x", "o" },
                function()
                    jump_to_pattern(camel_case_pattern, false)
                end,
                desc = "任意の単語の先頭へ移動",
            },
            {
                "T",
                mode = { "n", "x", "o" },
                function()
                    jump_to_pattern(camel_case_pattern, true)
                end,
                desc = "任意の単語の末尾へ移動",
            },
            {
                "<leader>p",
                paste_at_target,
                desc = "貼り付け（場所選択）",
            },
            {
                "S",
                mode = { "n", "x", "o" },
                function()
                    require("flash").treesitter()
                end,
                desc = "構文要素を選択",
            },
        },
    },
    {
        "andymass/vim-matchup",
        init = function()
            -- popupにすると一部のフローティングUIで崩れるため無効化
            vim.g.matchup_matchparen_offscreen = {}
        end,
    },
}
