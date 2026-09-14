-- Run: nvim --headless -u NONE -i NONE -l tests/nvim-formatting.lua
local setup, available, manual
available = {}
package.loaded.conform = {
    setup = function(opts) setup = opts end,
    get_formatter_info = function(name) return { available = available[name] == true } end,
    format = function(opts) manual = opts end,
}
local specs = dofile("dot_config/nvim/lua/plugins/edit.lua")
local configure
for _, spec in ipairs(specs) do
    if type(spec) == "table" and spec[1] == "stevearc/conform.nvim" then
        configure = spec.config
        configure()
    elseif type(spec) == "table" and spec[1] == "hashivim/vim-terraform" then
        spec.init()
        assert(vim.g.terraform_fmt_on_save == 0, "Duplicate Terraform save formatter")
    end
end
assert(setup.default_format_opts.lsp_format == "fallback")
assert(setup.default_format_opts.timeout_ms == 5000)
for _, ft in ipairs({ "javascript", "javascriptreact", "typescript", "typescriptreact", "json", "jsonc", "yaml" }) do
    assert(vim.deep_equal(setup.formatters_by_ft[ft], { "prettier" }), ft)
end
for _, ft in ipairs({ "sh", "bash" }) do
    assert(vim.deep_equal(setup.formatters_by_ft[ft], { "shfmt" }))
end
assert(vim.filetype.match({ filename = "script.sh" }) == "sh")
assert(vim.deep_equal(setup.formatters.shfmt.append_args, { "-i", "4" }))
assert(setup.formatters_by_ft.go.lsp_format == "prefer")
for _, case in ipairs({
    { { ruff_format = true, black = true, isort = true }, { "ruff_format" } },
    { { black = true, isort = true }, { "isort", "black" } },
    { { black = true }, { "black" } },
    { { isort = true }, {} },
    { {}, {} },
}) do
    available = case[1]
    assert(vim.deep_equal(setup.formatters_by_ft.python(0), case[2]))
end
for _, ft in ipairs({ "terraform", "terraform-vars" }) do
    vim.bo.filetype = ft
    local opts = setup.format_on_save(0)
    assert(opts.lsp_format == "never")
    assert(vim.deep_equal(opts.formatters, { "terraform_fmt" }))
end
for _, ft in ipairs({ "python", "sh", "javascript", "hcl" }) do
    vim.bo.filetype = ft
    assert(setup.format_on_save(0) == nil, "Unexpected save formatting: " .. ft)
end
vim.api.nvim_buf_set_name(0, "example.tftest.hcl")
assert(setup.format_on_save(0).formatters[1] == "terraform_fmt")
assert(setup.formatters_by_ft.hcl(0)[1] == "terraform_fmt")
vim.api.nvim_buf_set_name(0, "example.hcl")
assert(vim.deep_equal(setup.formatters_by_ft.hcl(0), {}))

-- Exercise the existing normal/visual manual-format callback.
local function inspect_keys(entries)
    for _, entry in ipairs(entries) do
        if type(entry) == "table" then
            if entry[1] == "m=" then entry[2]() end
            inspect_keys(entry)
        end
    end
end
package.loaded["which-key"] = { add = inspect_keys, setup = function() end }
package.loaded.treesj = { join = function() end, split = function() end, toggle = function() end }
dofile("dot_config/nvim/lua/plugins/which-key.lua").config()
assert(manual and manual.timeout_ms == 5000 and manual.lsp_fallback == nil)
assert(manual.lsp_format == nil, "Manual action must preserve per-filetype format policy")

local mason, registered, configure_none_ls
package.loaded["blink.cmp"] = { get_lsp_capabilities = function(c) return c end }
package.loaded["mason-null-ls"] = { setup = function(opts) mason = opts end }
package.loaded["null-ls"] = {
    setup = function() end,
    register = function(source) registered = source end,
    builtins = { diagnostics = { markdownlint = { with = function(opts) return opts end } } },
}
for _, spec in ipairs(dofile("dot_config/nvim/lua/plugins/lsp.lua")) do
    if spec[1] == "jay-babu/mason-null-ls.nvim" then
        configure_none_ls = spec.config
        configure_none_ls()
    end
end
assert(mason.methods.diagnostics)
for _, method in ipairs({ "formatting", "code_actions", "completion", "hover" }) do
    assert(mason.methods[method] == false, method)
end
assert(mason.handlers.shfmt == nil)
mason.handlers.markdownlint()
assert(vim.list_contains(registered.extra_args, "MD013"))
print("Passed formatter ownership, fallback, save-policy, and manual mapping checks")

-- Optional real-plugin/CLI smoke test; does not load Lazy or install anything.
if vim.env.NVIM_TEST_PLUGINS == "1" then
    package.loaded.conform = nil
    vim.opt.runtimepath:prepend(vim.fn.stdpath("data") .. "/lazy/conform.nvim")
    configure()
    local conform = require("conform")
    local function format(ft, filename, input, expected)
        vim.api.nvim_buf_set_name(0, filename)
        vim.bo.filetype = ft
        vim.api.nvim_buf_set_lines(0, 0, -1, false, input)
        local called = false
        conform.format({ bufnr = 0 }, function(err)
            assert(not err, tostring(err))
            called = true
        end)
        assert(called)
        assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), expected), ft)
    end
    format("sh", "/tmp/opencode/format-test.sh", { "if true; then", "echo hi", "fi" },
        { "if true; then", "    echo hi", "fi" })
    format("json", "/tmp/opencode/format-test.json", { '{"a":1}' }, { '{ "a": 1 }' })
    format("typescript", "/tmp/opencode/format-test.ts", { "const value:number=1" }, { "const value: number = 1;" })
    for _, case in ipairs({ { "typescriptreact", "tsx" }, { "javascriptreact", "jsx" } }) do
        format(case[1], "/tmp/opencode/format-test." .. case[2], { "const App=()=> <div />" },
            { "const App = () => <div />;" })
    end
    format("yaml", "/tmp/opencode/format-test.yaml", { "key:    value" }, { "key: value" })
    format("python", "/tmp/opencode/format-test.py", { "x=1" }, { "x = 1" })
    if vim.fn.executable("terraform") == 1 then
        format("terraform", "/tmp/opencode/format-test.tf", { "locals {", "x=1", "}" },
            { "locals {", "  x = 1", "}" })
    else
        print("SKIP: real Terraform formatting (terraform is not executable)")
    end
    local calls = 0
    conform.format = function(opts)
        calls = calls + 1
        assert(opts.formatters[1] == "terraform_fmt" and opts.lsp_format == "never")
    end
    vim.bo.filetype = "terraform"
    vim.api.nvim_exec_autocmds("BufWritePre", { buffer = 0 })
    assert(calls == 1, "Expected one Conform Terraform save hook")
    vim.bo.filetype = "sh"
    vim.api.nvim_exec_autocmds("BufWritePre", { buffer = 0 })
    assert(calls == 1, "Unexpected shell save formatting")
    print("Passed real Conform/shfmt/Prettier/Ruff formatting and save-hook checks")

    for _, plugin in ipairs({ "none-ls.nvim", "mason.nvim", "mason-null-ls.nvim", "plenary.nvim" }) do
        vim.opt.runtimepath:prepend(vim.fn.stdpath("data") .. "/lazy/" .. plugin)
    end
    package.loaded["null-ls"] = nil
    package.loaded["mason-null-ls"] = nil
    require("mason").setup()
    local bridge = require("mason-null-ls")
    local original_setup = bridge.setup
    bridge.setup = function(opts)
        -- Exercise installed-source registration without installing any tools.
        opts.ensure_installed = {}
        original_setup(opts)
    end
    configure_none_ls()
    local null_ls = require("null-ls")
    local markdown = false
    for _, source in ipairs(null_ls.get_sources()) do
        markdown = markdown or source.name == "markdownlint"
        for method in pairs(source.methods) do
            assert(method:match("^NULL_LS_DIAGNOSTICS"), source.name .. ": " .. method)
        end
    end
    assert(markdown, "Expected the installed markdownlint diagnostic source")
    print("Passed real mason-null-ls/none-ls diagnostics-only registration checks")
end
