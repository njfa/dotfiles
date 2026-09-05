local function normalize_dir(path)
    return vim.fs.normalize(vim.fs.abspath(path))
end

local function parent_dir(path)
    return vim.fn.fnamemodify(path, ":h")
end

local function is_file(path)
    return vim.fn.filereadable(path) == 1
end

local function find_upwards(start_dir, filename, stop_dir)
    local dir = normalize_dir(start_dir)
    local stop = stop_dir and normalize_dir(stop_dir) or nil

    while dir and dir ~= "" do
        if is_file(dir .. "/" .. filename) then
            return dir
        end
        if stop and dir == stop then
            return nil
        end

        local parent = parent_dir(dir)
        if parent == dir then
            return nil
        end
        dir = parent
    end
end

local function pom_has_modules(pom_path)
    local ok, lines = pcall(vim.fn.readfile, pom_path)
    if not ok then
        return false
    end

    -- Large POMs and profile-specific modules may occur after the first 200 lines.
    -- Ignore XML comments so a commented example does not select an unrelated root.
    local xml = table.concat(lines, "\n"):gsub("<!%-%-.-%-%->", "")
    return xml:match("<modules[%s>]") ~= nil
end

local function find_topmost_aggregator_pom(start_dir, git_root)
    local dir = normalize_dir(start_dir)
    local stop = git_root and normalize_dir(git_root) or nil
    local found = nil

    while dir and dir ~= "" do
        local pom = dir .. "/pom.xml"
        if is_file(pom) and pom_has_modules(pom) then
            found = dir
        end
        if stop and dir == stop then
            return found
        end

        local parent = parent_dir(dir)
        if parent == dir then
            return found
        end
        dir = parent
    end

    return found
end

local root_markers = {
    ".git",
    "gradlew",
    "mvnw",
    "pom.xml",
    "build.gradle",
    "build.gradle.kts",
    "settings.gradle",
    "settings.gradle.kts",
}
local M = {}

function M.find_root(filename)
    local current_file_dir = vim.fs.dirname(vim.fs.abspath(filename))
    local git_root = vim.fs.root(current_file_dir, ".git")
    return find_upwards(current_file_dir, ".jdtls-root", git_root)
        or find_topmost_aggregator_pom(current_file_dir, git_root)
        or vim.fs.root(current_file_dir, { root_markers })
end

return M
