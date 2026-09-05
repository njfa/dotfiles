local M = {}
local checked = {}

function M.java_in(home)
    local suffix = vim.fn.has('win32') == 1 and '/bin/java.exe' or '/bin/java'
    for _, base in ipairs({ home .. '/Contents/Home', home }) do
        if vim.fn.executable(base .. suffix) == 1 then
            return base .. suffix
        end
    end
end

function M.resolve()
    local candidates = {}
    if vim.env.JDTLS_JAVA_HOME then
        return assert(M.java_in(vim.env.JDTLS_JAVA_HOME), 'JDTLS_JAVA_HOMEにjavaがありません')
    end
    for _, home in ipairs(vim.fn.glob(vim.fn.stdpath('data') .. '/mason/packages/openjdk-21/jdk-21.*', true, true)) do
        table.insert(candidates, home)
    end
    if vim.env.JAVA_HOME then table.insert(candidates, vim.env.JAVA_HOME) end
    for _, home in ipairs(candidates) do
        local java = M.java_in(home)
        if java then return java end
    end
    local java = vim.fn.exepath('java')
    assert(java ~= '', 'JDT LSにはJDK 21以降が必要です。:MasonInstall openjdk-21 またはJDTLS_JAVA_HOMEを設定してください')
    return java
end

function M.validate(java)
    if checked[java] then return end
    local result = vim.system({ java, '-version' }, { text = true }):wait(10000)
    local version = ((result.stderr or '') .. (result.stdout or '')):match('version%s+"(%d+)')
    assert(result.code == 0 and tonumber(version or 0) >= 21, 'JDT LS起動用javaにはJDK 21以降が必要です: ' .. java)
    checked[java] = true
end

function M.limits()
    local available = vim.uv.available_parallelism and vim.uv.available_parallelism() or #vim.uv.cpu_info()
    local cpus = tonumber(vim.env.JDTLS_CPUS or math.min(4, math.max(1, math.floor(available / 2))))
    assert(cpus and cpus >= 1 and cpus % 1 == 0, 'JDTLS_CPUSは1以上の整数で指定してください')
    local heap = vim.env.JDTLS_MAX_HEAP or '2g'
    local value, unit = heap:lower():match('^(%d+)([mg])$')
    assert(value and tonumber(value) * (unit == 'g' and 1024 or 1) >= 256,
        'JDTLS_MAX_HEAPは256m以上で指定してください（例: 2g）')
    return cpus, heap
end

return M
