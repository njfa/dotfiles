-- Manual benchmark for an installed Neovim configuration.
-- Usage:
--   JDTLS_BENCHMARK_FILE=/path/to/Type.java \
--   JDTLS_BENCHMARK_SYMBOL=Type nvim --headless -l tests/manual/nvim-java-benchmark.lua
local file = assert(vim.env.JDTLS_BENCHMARK_FILE, "JDTLS_BENCHMARK_FILE is required")
file = vim.fs.abspath(file)
assert(vim.fn.filereadable(file) == 1, "File does not exist: " .. file)

local started = vim.uv.hrtime()
local peak_rss_kib = 0
local java_pid

local function elapsed()
    return (vim.uv.hrtime() - started) / 1e9
end

local function sample_java()
    if not java_pid then
        local result = vim.system({ "pgrep", "-P", tostring(vim.fn.getpid()), "java" }, { text = true }):wait(1000)
        java_pid = result.code == 0 and tonumber((result.stdout or ""):match("%d+")) or nil
    end
    if java_pid then
        local result = vim.system({ "ps", "-o", "rss=", "-p", tostring(java_pid) }, { text = true }):wait(1000)
        peak_rss_kib = math.max(peak_rss_kib, tonumber((result.stdout or ""):match("%d+")) or 0)
    end
end

local function wait_for(timeout, condition)
    return vim.wait(timeout, function()
        sample_java()
        return condition()
    end, 250)
end

vim.cmd.edit(vim.fn.fnameescape(file))
local client
assert(wait_for(120000, function()
    client = vim.lsp.get_clients({ bufnr = 0, name = "jdtls" })[1]
    return client and client.initialized
end), "JDT LS did not initialize")
local initialized_seconds = elapsed()

local workspace_dir
for index, part in ipairs(client.config.cmd or {}) do
    if part == "-data" or part == "--data" then workspace_dir = client.config.cmd[index + 1] end
end
local function project_count()
    if not workspace_dir then return 0 end
    local project_dir = workspace_dir .. "/.metadata/.plugins/org.eclipse.core.resources/.projects"
    return vim.iter(vim.fn.glob(project_dir .. "/*", true, true)):fold(0, function(count, path)
        return count + (vim.fn.isdirectory(path) == 1 and 1 or 0)
    end)
end
local function ready_project_count()
    if not workspace_dir then return 0 end
    local project_dir = workspace_dir .. "/.metadata/.plugins/org.eclipse.core.resources/.projects"
    return #vim.fn.glob(project_dir .. "/*/.syncinfo.snap", true, true)
end
local expected_projects = tonumber(vim.env.JDTLS_BENCHMARK_PROJECTS or "0")
if expected_projects > 0 then
    assert(wait_for(300000, function() return ready_project_count() >= expected_projects end),
        ("JDT LS prepared %d/%d expected projects"):format(ready_project_count(), expected_projects))
end
local imported_seconds = elapsed()
local usable_seconds = imported_seconds

local symbol = vim.env.JDTLS_BENCHMARK_SYMBOL or vim.fs.basename(file):gsub("%.java$", "")
local symbol_response = client:request_sync("workspace/symbol", { query = symbol }, 10000, 0)
local symbols = symbol_response and not symbol_response.err and symbol_response.result or {}

-- Sample a little longer because JDT LS may keep importing after its first useful response.
local sample_until = vim.uv.hrtime() + 10e9
wait_for(15000, function() return vim.uv.hrtime() >= sample_until end)

local commands = (client.server_capabilities.executeCommandProvider or {}).commands or {}
local result = {
    file = file,
    root_dir = client.config.root_dir,
    initialized_seconds = tonumber(("%.2f"):format(initialized_seconds)),
    usable_seconds = tonumber(("%.2f"):format(usable_seconds)),
    peak_java_rss_mib = tonumber(("%.1f"):format(peak_rss_kib / 1024)),
    symbol = symbol,
    symbol_results = #symbols,
    projects = project_count(),
    ready_projects = ready_project_count(),
    imported_seconds = tonumber(("%.2f"):format(imported_seconds)),
    diagnostics = #vim.diagnostic.get(0),
    java_debug_available = vim.tbl_contains(commands, "vscode.java.startDebugSession"),
}
print(vim.json.encode(result))
client:stop(true)
vim.wait(3000, function() return client:is_stopped() end, 50)
