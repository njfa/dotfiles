local M = {}

local function add_glob(result, seen, pattern)
    for _, path in ipairs(vim.fn.glob(pattern, true, true)) do
        path = vim.fs.normalize(path)
        if vim.fn.filereadable(path) == 1 and not seen[path] then
            seen[path] = true
            table.insert(result, path)
        end
    end
end

function M.collect(packages_dir)
    local result, seen = {}, {}
    add_glob(result, seen, packages_dir .. "/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar")

    local jdtls_bundles = {}
    for _, path in ipairs(vim.fn.glob(packages_dir .. "/jdtls/plugins/*.jar", true, true)) do
        jdtls_bundles[vim.fs.basename(path)] = true
    end

    -- vscode-java-test declares the exact OSGi bundles it needs. Loading every
    -- JAR in server/ also loads runner agents. A declared bundle may already be
    -- included in a newer JDT LS, in which case installing it twice fails.
    local extension_dir = packages_dir .. "/java-test/extension"
    local package_json = extension_dir .. "/package.json"
    if vim.fn.filereadable(package_json) == 1 then
        local ok, metadata = pcall(vim.json.decode, table.concat(vim.fn.readfile(package_json), "\n"))
        if ok then
            local extensions = (((metadata or {}).contributes or {}).javaExtensions or {})
            for _, relative_path in ipairs(extensions) do
                local path = vim.fs.normalize(extension_dir .. "/" .. relative_path:gsub("^%./", ""))
                if vim.fn.filereadable(path) == 1 and not seen[path] and not jdtls_bundles[vim.fs.basename(path)] then
                    seen[path] = true
                    table.insert(result, path)
                end
            end
        else
            vim.notify("java-testのpackage.jsonを読み込めません: " .. tostring(metadata), vim.log.levels.WARN)
        end
    end

    add_glob(result, seen, packages_dir .. "/vscode-java-decompiler/server/*.jar")
    return result
end

return M
