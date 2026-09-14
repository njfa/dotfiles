-- Run: nvim --headless -u NONE -i NONE -l tests/nvim-textobjects.lua
-- Requires the locked plugins in stdpath("data")/lazy and a Python parser.
vim.g.mapleader = " "
local lazy = vim.fn.stdpath("data") .. "/lazy/"
for _, plugin in ipairs({ "nvim-treesitter", "nvim-treesitter-textobjects", "targets.vim" }) do
    assert(vim.fn.isdirectory(lazy .. plugin) == 1, "Missing installed plugin: " .. plugin)
    vim.opt.runtimepath:prepend(lazy .. plugin)
end
vim.cmd("runtime plugin/targets.vim")
vim.cmd("filetype plugin on")
vim.bo.filetype = "python"
local builtin_motion = vim.fn.maparg("]m", "n", false, true)
local options = { vim.o.foldexpr, vim.o.foldmethod, vim.o.foldlevel, vim.bo.indentexpr }
for _, spec in ipairs(dofile("dot_config/nvim/lua/plugins/treesitter.lua")) do
    if type(spec) == "table" and spec[1] == "nvim-treesitter/nvim-treesitter-textobjects" then
        assert(spec.branch == "main")
        assert(spec.dependencies == "nvim-treesitter/nvim-treesitter")
        spec.config()
    end
end
assert(vim.deep_equal(builtin_motion, vim.fn.maparg("]m", "n", false, true)))
assert(vim.deep_equal(options, { vim.o.foldexpr, vim.o.foldmethod, vim.o.foldlevel, vim.bo.indentexpr }))
assert(vim.g.no_plugin_maps == nil)
for _, mode in ipairs({ "x", "o" }) do
    for _, key in ipairs({ "af", "if", "ac", "ic", "aP", "iP" }) do
        assert(type(vim.fn.maparg(key, mode, false, true).callback) == "function", mode .. key)
    end
end
for _, mode in ipairs({ "n", "x", "o" }) do
    for _, key in ipairs({ "]r", "[r", "]R", "[R" }) do
        assert(type(vim.fn.maparg(key, mode, false, true).callback) == "function", mode .. key)
    end
    for _, key in ipairs({ ";", ",", "[f", "]f" }) do
        assert(vim.fn.maparg(key, mode) == "", "Unexpected override: " .. key)
    end
end

local lines = {
    "class Example:",
    "    def first(self, alpha, beta):",
    "        return alpha + beta",
    "",
    "    def second(self, gamma):",
    "        return gamma",
}
vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
vim.treesitter.get_parser(0, "python"):parse()
local function normal(keys, row, col)
    vim.api.nvim_win_set_cursor(0, { row, col })
    vim.cmd.normal({ args = { keys }, bang = false })
end

local selections = {
    { "af", 2, 8, "def first(self, alpha, beta):\n        return alpha + beta" },
    { "if", 3, 10, "return alpha + beta" },
    { "ac", 1, 0, table.concat(lines, "\n") },
    { "ic", 2, 8, "def first(self, alpha, beta):\n        return alpha + beta\n\n    def second(self, gamma):\n        return gamma" },
    { "aP", 2, 21, ", alpha" },
    { "iP", 2, 21, "alpha" },
}
for _, case in ipairs(selections) do
    for _, prefix in ipairs({ "y", "v" }) do
        normal(prefix .. case[1] .. (prefix == "v" and "y" or ""), case[2], case[3])
        assert(vim.fn.getreg('"') == case[4], case[1] .. ": " .. vim.inspect(vim.fn.getreg('"')))
    end
end
for _, case in ipairs({
    { "]r", 1, 2 }, { "[r", 6, 5 }, { "]R", 2, 3 }, { "[R", 5, 3 }, { "2]r", 1, 5 },
}) do
    normal(case[1], case[2], 0)
    assert(vim.api.nvim_win_get_cursor(0)[1] == case[3], case[1])
end
assert(#vim.fn.getjumplist()[1] > 0)
normal(" >", 2, 21)
assert(vim.api.nvim_buf_get_lines(0, 1, 2, false)[1] == "    def first(self, beta, alpha):")
normal(" <", 2, 25)
assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), lines))
normal("yiP", 4, 0)
assert(vim.fn.getreg('"') == "self", "Parameter lookahead")
normal("yia", 2, 21)
assert(vim.fn.getreg('"') == " alpha", "targets.vim argument selection")
normal("yip", 2, 21)
assert(vim.fn.getreg('"') == table.concat({ lines[1], lines[2], lines[3], "" }, "\n"), "Paragraph selection")
print("Passed textobject selections, motions, swaps, and preservation checks")
