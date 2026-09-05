-- nvim --headless -u NONE -l tests/nvim-debugging.lua
vim.opt.rtp:prepend(vim.fn.getcwd() .. '/dot_config/nvim')
local runtime = require('java_runtime')
local debugging = require('debugging')
local java_bundles = require('java_bundles')
local tmp = vim.fn.tempname()
local function write(path, text, executable)
    path = tmp .. '/' .. path
    vim.fn.mkdir(vim.fs.dirname(path), 'p')
    vim.fn.writefile({ text or '' }, path)
    if executable then vim.fn.setfperm(path, 'rwxr-xr-x') end
    return path
end
local original_cpus, original_heap = vim.env.JDTLS_CPUS, vim.env.JDTLS_MAX_HEAP
local ok, err = xpcall(function()
    local suffix = vim.fn.has('win32') == 1 and 'java.exe' or 'java'
    local java = write('mac-jdk/Contents/Home/bin/' .. suffix, '', true)
    assert(runtime.java_in(tmp .. '/mac-jdk') == java)
    assert(runtime.java_in(tmp .. '/missing') == nil)
    local debug_jar = write('packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-1.jar')
    local test_jar = write('packages/java-test/extension/server/com.microsoft.java.test.plugin-1.jar')
    local duplicate_jar = write('packages/java-test/extension/server/org.objectweb.asm_9.jar')
    write('packages/jdtls/plugins/org.objectweb.asm_9.jar')
    write('packages/java-test/extension/server/runner.jar')
    write('packages/java-test/extension/package.json', vim.json.encode({
        contributes = { javaExtensions = {
            './server/com.microsoft.java.test.plugin-1.jar',
            './server/org.objectweb.asm_9.jar',
        } },
    }))
    local bundles = java_bundles.collect(tmp .. '/packages')
    assert(vim.tbl_contains(bundles, debug_jar))
    assert(vim.tbl_contains(bundles, test_jar))
    assert(not vim.tbl_contains(bundles, duplicate_jar))
    assert(not vim.iter(bundles):any(function(path) return vim.endswith(path, '/runner.jar') end))
    vim.env.JDTLS_CPUS, vim.env.JDTLS_MAX_HEAP = '1', '512m'
    local cpus, heap = runtime.limits()
    assert(cpus == 1 and heap == '512m')
    vim.env.JDTLS_CPUS = '0'
    assert(not pcall(runtime.limits))
    vim.env.JDTLS_CPUS, vim.env.JDTLS_MAX_HEAP = '2', '128m'
    assert(not pcall(runtime.limits))
    vim.env.JDTLS_MAX_HEAP = '2g -Xmx8g'
    assert(not pcall(runtime.limits))

    local launch = write('repo/.vscode/launch.json', '{}')
    assert(debugging.launch_file(write('no-project/main.py')) == nil)
    write('repo/.git')
    local file = write('repo/module/src/main.py')
    assert(debugging.launch_file(file) == launch)
    write('repo/module/.git')
    assert(debugging.launch_file(file) == nil, 'Must respect nested Git boundary')
    vim.fn.delete(tmp .. '/repo/module/.git')
    local dap = { providers = { configs = {} }, adapters = {}, configurations = {} }
    package.loaded.dap = dap
    package.loaded['dap.utils'] = { pick_process = function() return 42 end }
    package.loaded['dap.ext.vscode'] = { getconfigs = function(path)
        assert(path == launch)
        return { { cwd = '${workspaceFolder}', program = '${workspaceFolder}/module/main.py' } }
    end }
    debugging.setup()
    vim.cmd.edit(file)
    local configs = dap.providers.configs['dap.launch.json'](0)
    assert(configs[1].cwd == tmp .. '/repo')
    assert(configs[1].program == tmp .. '/repo/module/main.py')
    local adapter
    dap.adapters.python(function(value) adapter = value end,
        { request = 'attach', connect = { host = '127.0.0.1', port = 5678 } })
    assert(adapter.type == 'server' and adapter.port == 5678)
    dap.adapters.go(function(value) adapter = value end, { cwd = tmp .. '/repo/module' })
    assert(adapter.executable.args[2] == '--listen=127.0.0.1:${port}')
    assert(adapter.executable.cwd == tmp .. '/repo/module')
end, debug.traceback)
vim.env.JDTLS_CPUS, vim.env.JDTLS_MAX_HEAP = original_cpus, original_heap
vim.fn.delete(tmp, 'rf')
assert(ok, err)
print('Java runtime, resource limits and DAP workspace checks passed')
