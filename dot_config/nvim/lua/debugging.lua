local M = {}

function M.launch_file(filename)
    local dir = filename ~= '' and vim.fs.dirname(vim.fs.abspath(filename)) or vim.fn.getcwd()
    while dir do
        local path = dir .. '/.vscode/launch.json'
        if vim.fn.filereadable(path) == 1 then return path end
        if vim.uv.fs_stat(dir .. '/.git') then break end
        local parent = vim.fs.dirname(dir)
        if parent == dir then break end
        dir = parent
    end
end

function M.root()
    local file = vim.api.nvim_buf_get_name(0)
    local launch = M.launch_file(file)
    if launch then return vim.fs.dirname(vim.fs.dirname(launch)) end
    return vim.fs.root(0, { { 'pyproject.toml', 'pyrightconfig.json', 'go.mod', '.git' } }) or vim.fn.getcwd()
end

function M.python()
    if vim.env.VIRTUAL_ENV then
        for _, suffix in ipairs({ '/bin/python', '/Scripts/python.exe' }) do
            local path = vim.env.VIRTUAL_ENV .. suffix
            if vim.fn.executable(path) == 1 then return path end
        end
    end
    for _, suffix in ipairs({ '/.venv/bin/python', '/.venv/Scripts/python.exe' }) do
        local path = M.root() .. suffix
        if vim.fn.executable(path) == 1 then return path end
    end
    return vim.fn.exepath('python3') ~= '' and vim.fn.exepath('python3') or vim.fn.exepath('python')
end

local function port(default)
    local value = tonumber(vim.fn.input('デバッグポート: ', tostring(default)))
    assert(value and value >= 1 and value <= 65535 and value % 1 == 0, 'ポートは1〜65535で指定してください')
    return value
end

function M.setup()
    local dap = require('dap')
    dap.providers.configs['dap.launch.json'] = function(bufnr)
        local path = M.launch_file(vim.api.nvim_buf_get_name(bufnr))
        if not path then return {} end
        local configs = require('dap.ext.vscode').getconfigs(path)
        -- nvim-dap expands workspaceFolder from cwd; bind it to this launch.json instead.
        local root = vim.fs.dirname(vim.fs.dirname(path))
        local function expand(value)
            if type(value) == 'string' then
                return (value:gsub('%${workspaceFolder}', function() return root end))
            elseif type(value) == 'table' then
                local copy = {}
                for k, v in pairs(value) do copy[k] = expand(v) end
                return copy
            end
            return value
        end
        return expand(configs)
    end
    dap.adapters.python = function(callback, config)
        if config.request == 'attach' then
            callback({ type = 'server', host = (config.connect or {}).host or '127.0.0.1',
                port = assert((config.connect or {}).port, 'connect.portが必要です') })
        else
            local python = vim.fn.stdpath('data') .. '/mason/packages/debugpy/venv/'
                .. (vim.fn.has('win32') == 1 and 'Scripts/python.exe' or 'bin/python')
            assert(vim.fn.executable(python) == 1, ':MasonInstall debugpy を実行してください')
            callback({ type = 'executable', command = python, args = { '-m', 'debugpy.adapter' } })
        end
    end
    dap.adapters.debugpy = dap.adapters.python
    dap.adapters.go = function(callback, config)
        callback({
            type = 'server', host = '127.0.0.1', port = '${port}',
            executable = { command = 'dlv', args = { 'dap', '--listen=127.0.0.1:${port}' },
                cwd = config.cwd or vim.fn.getcwd() },
        })
    end
    dap.configurations.java = {
        { type = 'java', request = 'attach', name = '実行中のJVMにアタッチ (ポート指定)',
            hostName = '127.0.0.1', port = function() return port(5005) end },
    }
    dap.configurations.python = {
        { type = 'python', request = 'launch', name = 'Python: 現在のファイル', program = '${file}',
            pythonPath = M.python, cwd = M.root, console = 'integratedTerminal', justMyCode = true },
        { type = 'python', request = 'attach', name = 'Python: debugpyに接続',
            connect = function() return { host = '127.0.0.1', port = port(5678) } end },
    }
    dap.configurations.go = {
        { type = 'go', request = 'launch', name = 'Go: 現在のパッケージ', mode = 'debug',
            program = '${fileDirname}', cwd = '${fileDirname}' },
        { type = 'go', request = 'launch', name = 'Go: パッケージのテスト', mode = 'test',
            program = '${fileDirname}', cwd = '${fileDirname}' },
        { type = 'go', request = 'attach', name = 'Go: ローカルプロセスに接続', mode = 'local',
            processId = require('dap.utils').pick_process },
    }
end

return M
