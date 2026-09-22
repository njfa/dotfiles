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
-- Stand in for upstream lspconfig definitions without loading plugins or servers.
local server_filetypes = {
    ts_ls = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
    lua_ls = { "lua" },
    pyright = { "python" },
    ruff = { "python" },
    gopls = { "go", "gomod", "gowork", "gotmpl" },
    tflint = { "terraform" },
    terraformls = { "terraform", "terraform-vars" },
}
for name, filetypes in pairs(server_filetypes) do
    vim.lsp.config(name, { cmd = { "unused-test-server" }, filetypes = filetypes })
end
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
assert(mason_options.automatic_enable == false, "Mason must not enable installed servers automatically")
print("Passed shared LSP attachment and Mason configuration checks")

local control = require("lsp_control")
assert(not control.is_enabled("jdtls"))
assert(not control.is_enabled("terraformls"))
assert(not vim.lsp.is_enabled("jdtls"))
for _, name in ipairs(require("lsp_policy").servers) do
    assert(not control.is_enabled(name), name .. " must default to disabled")
end
assert(not control.is_enabled("null-ls"))

-- Disabled Java must return before loading plugins or probing the Java runtime.
package.preload.jdtls = function() error("Disabled jdtls must not be loaded") end
dofile("dot_config/nvim/ftplugin/java.lua")

-- Exercise existing-buffer activation without requiring an installed JVM/server.
local java_buffers = {}
for _ = 1, 2 do
    local bufnr = vim.api.nvim_create_buf(true, false)
    vim.bo[bufnr].filetype = "java"
    table.insert(java_buffers, bufnr)
end
local original_dofile = dofile
local starts = {}
_G.dofile = function(path)
    assert(path:match("/ftplugin/java.lua$"))
    assert(control.is_enabled("jdtls"))
    table.insert(starts, vim.api.nvim_get_current_buf())
end
vim.cmd("LspEnable jdtls")
assert(vim.deep_equal(starts, java_buffers))
assert(not vim.lsp.is_enabled("jdtls"), "Java must keep using nvim-jdtls")

local original_get_clients = vim.lsp.get_clients
local stops = 0
vim.lsp.get_clients = function(filter)
    assert(filter.name == "jdtls")
    return {
        { stop = function() stops = stops + 1 end },
        { stop = function() stops = stops + 1 end },
    }
end
vim.cmd("LspDisable jdtls")
assert(stops == 2, "Disable must stop clients across all roots")
assert(not control.is_enabled("jdtls"))
vim.lsp.get_clients = original_get_clients
_G.dofile = original_dofile
dofile("dot_config/nvim/ftplugin/java.lua")
assert(#starts == 2, "Opening Java while disabled must not restart clients")

-- Enable before opening a Java buffer, then toggle back off.
for _, bufnr in ipairs(java_buffers) do
    vim.api.nvim_buf_delete(bufnr, { force = true })
end
vim.cmd("LspToggle jdtls")
assert(control.is_enabled("jdtls"))
vim.cmd("LspToggle jdtls")
assert(not control.is_enabled("jdtls"))

vim.cmd("LspEnable terraformls")
assert(control.is_enabled("terraformls"))
vim.cmd("LspDisable terraformls")
assert(not control.is_enabled("terraformls"))
vim.cmd("LspToggle terraformls")
assert(control.is_enabled("terraformls"))
vim.cmd("LspToggle terraformls")
assert(not control.is_enabled("terraformls"))
assert(not pcall(control.set_enabled, "typo", true))
assert(vim.deep_equal(vim.fn.getcompletion("LspEnable terra", "cmdline"), { "terraformls" }))
vim.cmd("LspStatus")

-- An argument-free toggle selects the server from the current buffer's filetype.
_G.dofile = function(path)
    assert(path:match("/ftplugin/java.lua$"))
    assert(control.is_enabled("jdtls"))
end
for filetype, targets in pairs({
    java = { "jdtls" },
    terraform = { "terraformls", "tflint" },
    ["terraform-vars"] = { "terraformls" },
    python = { "pyright", "ruff" },
    lua = { "lua_ls" },
    go = { "gopls" },
    gomod = { "gopls" },
    typescript = { "ts_ls" },
    javascriptreact = { "ts_ls" },
}) do
    vim.bo.filetype = filetype
    vim.cmd("LspToggle")
    for _, name in ipairs(targets) do
        assert(control.is_enabled(name), filetype .. " should enable " .. name)
    end
    vim.cmd("LspToggle")
    for _, name in ipairs(targets) do
        assert(not control.is_enabled(name), filetype .. " should disable " .. name)
    end
end
_G.dofile = original_dofile
vim.bo.filetype = "text"
vim.cmd("LspToggle")
assert(not control.is_enabled("jdtls") and not control.is_enabled("terraformls"))

-- Startup exceptions only enable named servers, and mixed groups toggle as a unit.
local policy = require("lsp_policy")
policy.default_enabled = { "ruff", "lua_ls" }
control.apply_defaults()
for _, name in ipairs(policy.servers) do
    assert(control.is_enabled(name) == (name == "ruff" or name == "lua_ls"))
end
vim.bo.filetype = "python"
vim.cmd("LspToggle")
assert(control.is_enabled("pyright") and control.is_enabled("ruff"))
vim.cmd("LspToggle")
assert(not control.is_enabled("pyright") and not control.is_enabled("ruff"))
vim.cmd("LspEnable")
assert(control.is_enabled("pyright") and control.is_enabled("ruff"))
vim.cmd("LspDisable")
assert(not control.is_enabled("pyright") and not control.is_enabled("ruff"))
assert(control.is_enabled("lua_ls"), "Python toggles must not change other languages")
vim.cmd("LspDisable lua_ls")
policy.default_enabled = { "jdtls" }
control.apply_defaults()
assert(control.is_enabled("jdtls") and not vim.lsp.is_enabled("jdtls"))
vim.cmd("LspDisable jdtls")
policy.default_enabled = {}

-- none-ls must respect the same opt-in policy instead of starting on FileType.
local null_options
package.loaded["null-ls"] = { setup = function(opts) null_options = opts end }
package.loaded["mason-null-ls"] = { setup = function() end }
for _, spec in ipairs(specs) do
    if spec[1] == "jay-babu/mason-null-ls.nvim" then
        spec.config()
    end
end
assert(null_options and not null_options.should_attach())
local attempts = 0
package.loaded["null-ls.sources"] = {
    get_available = function(ft) return ft == "markdown" and { {} } or {} end,
}
package.loaded["null-ls.client"] = {
    try_add = function(bufnr)
        assert(null_options.should_attach())
        assert(vim.api.nvim_get_current_buf() == bufnr)
        attempts = attempts + 1
    end,
}
vim.bo.filetype = "markdown"
vim.cmd("LspToggle")
assert(control.is_enabled("null-ls") and attempts > 0)
local null_stopped = false
vim.lsp.get_clients = function(filter)
    assert(filter.name == "null-ls")
    return { { stop = function() null_stopped = true end } }
end
vim.cmd("LspToggle")
assert(null_stopped and not null_options.should_attach())
vim.lsp.get_clients = original_get_clients
print("Passed opt-in LSP lifecycle checks")
