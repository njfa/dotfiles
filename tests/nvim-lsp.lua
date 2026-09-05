-- Run from the repository root: nvim --headless -u NONE -l tests/nvim-lsp.lua
vim.opt.runtimepath:prepend(vim.fn.getcwd() .. "/dot_config/nvim")
local root = require("java_root")
local tmp = vim.fn.tempname()
local checks = 0

local function write(path, contents)
    vim.fn.mkdir(vim.fs.dirname(tmp .. "/" .. path), "p")
    vim.fn.writefile(vim.split(contents or "", "\n", { plain = true }), tmp .. "/" .. path)
end

local function expect(file, expected)
    write(file, "class Example {}")
    local actual = root.find_root(tmp .. "/" .. file)
    assert(actual == tmp .. "/" .. expected, vim.inspect({ file = file, expected = expected, actual = actual }))
    checks = checks + 1
end

local ok, err = xpcall(function()
    write("repo/.git", "gitdir: /some/worktree")
    write("repo/pom.xml", "<project>\n" .. string.rep("\n", 220)
        .. "<modules\n><module>group</module><module>other</module></modules></project>")
    write("repo/group/pom.xml", "<project><modules><module>child</module></modules></project>")
    write("repo/group/child/pom.xml", "<project/>")
    write("repo/other/pom.xml", "<project/>")
    expect("repo/group/child/src/Example.java", "repo")
    expect("repo/other/src/Example.java", "repo")

    -- An explicit marker can narrow an otherwise shared Maven workspace.
    write("repo/group/.jdtls-root")
    expect("repo/group/child/src/Example.java", "repo/group")

    -- Do not escape a nested Git repository to pick up an unrelated aggregator.
    vim.fn.mkdir(tmp .. "/repo/nested/.git", "p")
    write("repo/nested/app/pom.xml", "<project/>")
    expect("repo/nested/app/src/Example.java", "repo/nested/app")

    -- A commented modules example is not an aggregator.
    write("comments/.git")
    write("comments/pom.xml", "<project><!--\n<modules><module>app</module></modules>\n--></project>")
    write("comments/app/pom.xml", "<project/>")
    expect("comments/app/src/Example.java", "comments/app")

    -- Source archives without Git still share the outermost aggregator.
    write("archive/pom.xml", "<project><modules><module>app</module></modules></project>")
    write("archive/app/pom.xml", "<project/>")
    expect("archive/app/src/Example.java", "archive")

    write("gradle/settings.gradle.kts")
    expect("gradle/src/Example.java", "gradle")
end, debug.traceback)
vim.fn.delete(tmp, "rf")
if not ok then
    error(err)
end
print(("Passed %d Java root checks"):format(checks))

-- Exercise shared attachment independently of server-specific on_attach callbacks.
package.loaded["blink.cmp"] = {
    get_lsp_capabilities = function(capabilities) return capabilities end,
}
local attached = {}
package.loaded.common = {
    on_attach_lsp = function(client, bufnr)
        table.insert(attached, { client.name, bufnr })
    end,
}
local specs = dofile("dot_config/nvim/lua/plugins/lsp.lua")
local original_get_client = vim.lsp.get_client_by_id
for _, name in ipairs({ "pyright", "ruff", "gopls", "jdtls" }) do
    local client = { name = name, server_capabilities = { hoverProvider = true } }
    vim.lsp.get_client_by_id = function() return client end
    vim.api.nvim_exec_autocmds("LspAttach", { buffer = 0, data = { client_id = 1 } })
    assert(attached[#attached][1] == name)
    assert(client.server_capabilities.hoverProvider == (name ~= "ruff"))
end
vim.lsp.get_client_by_id = original_get_client

local mason_options
package.loaded["mason-lspconfig"] = { setup = function(opts) mason_options = opts end }
for _, spec in ipairs(specs) do
    if spec[1] == "mason-org/mason-lspconfig.nvim" then
        spec.config()
    end
end
assert(mason_options)
for _, name in ipairs({ "pyright", "ruff", "gopls", "jdtls" }) do
    assert(vim.tbl_contains(mason_options.ensure_installed, name))
end
assert(vim.tbl_contains(mason_options.automatic_enable.exclude, "jdtls"))
assert(vim.tbl_contains(mason_options.automatic_enable.exclude, "pylsp"))
print("Passed shared LSP attachment and Mason configuration checks")
