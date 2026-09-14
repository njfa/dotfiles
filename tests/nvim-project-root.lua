-- Run: nvim --headless -u NONE -i NONE -l tests/nvim-project-root.lua
local repo = vim.fn.getcwd()
vim.opt.runtimepath:prepend(repo .. "/dot_config/nvim")
local common = require("common")
local tmp = vim.fn.tempname()
local function write(path, lines)
    vim.fn.mkdir(vim.fs.dirname(tmp .. "/" .. path), "p")
    vim.fn.writefile(lines or {}, tmp .. "/" .. path)
end
local function buffer(path, buftype)
    local buf = path and vim.fn.bufadd(tmp .. "/" .. path) or vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_current_buf(buf)
    vim.bo.buftype = buftype or ""
end
local function expect(path, git)
    assert(common.get_cwd() == tmp .. "/" .. path, vim.inspect({ expected = path, actual = common.get_cwd() }))
    assert(common.is_git_repo() == git)
end

local ok, err = xpcall(function()
    write("repo/.git/config")
    write("repo/src/file.lua")
    write("work tree/.git", { "gitdir: ../repo/.git/worktrees/example" })
    write("work tree/src/file.lua")
    write("repo/submodule/.git", { "gitdir: ../.git/modules/submodule" })
    write("repo/submodule/src/file.lua")
    write("plain/file.lua")
    vim.api.nvim_set_current_dir(tmp .. "/plain")
    buffer("repo/src/file.lua")
    expect("repo", true)
    buffer("work tree/src/file.lua")
    expect("work tree", true)
    buffer("repo/submodule/src/file.lua")
    expect("repo/submodule", true)
    buffer("repo/src/new-file.lua")
    expect("repo", true)
    buffer("repo/src")
    expect("repo", true)
    buffer("plain/file.lua")
    expect("plain", false)
    buffer(nil)
    expect("plain", false)
    vim.cmd("lcd " .. vim.fn.fnameescape(tmp .. "/repo/src"))
    expect("repo", true)
    buffer("plain/file.lua")
    expect("repo/src", false) -- A non-project file falls back to the effective cwd.
    buffer("plain/special", "nofile")
    expect("repo", true)
    buffer("work tree/src/file.lua")

    local ui = dofile(repo .. "/dot_config/nvim/lua/plugins/ui.lua")
    local snacks
    for _, spec in ipairs(ui) do
        if type(spec) == "table" and spec[1] == "folke/snacks.nvim" then snacks = spec end
    end
    assert(snacks)
    local config = snacks.opts.picker
    assert(config.sources.files.cmd == "rg", "Avoid a non-ignore-aware find fallback")
    local called
    local function capture(source, opts)
        opts = vim.tbl_deep_extend("force", { source = source }, config.sources[source] or {}, opts or {})
        config.config(opts)
        called = opts
    end
    _G.Snacks = {
        picker = setmetatable({}, { __index = function(_, source)
            return function(opts) capture(source, opts) end
        end }),
        explorer = function(opts) capture("explorer", opts) end,
    }
    for _, case in ipairs({
        { "<leader>f", "files", false }, { "<leader>g", "grep", false },
        { "<leader>F", "files", true }, { "<leader>G", "grep", true },
        { "<leader><leader>f", "git_files" }, { "<leader><leader>gg", "git_grep" },
        { "<leader><leader>gs", "git_status" },
    }) do
        called = nil
        for _, key in ipairs(snacks.keys) do
            if key[1] == case[1] then key[2]() end
        end
        assert(called and called.source == case[2], case[1])
        assert(called.cwd == common.get_cwd(), case[1])
        if case[3] ~= nil then assert(called.ignored == case[3] and called.hidden, case[1]) end
    end
    local explicit = { source = "files", cwd = tmp .. "/plain" }
    config.config(explicit)
    assert(explicit.cwd == tmp .. "/plain")
    local scoped = { source = "grep", dirs = { "relative-yazi-directory" } }
    config.config(scoped)
    assert(scoped.cwd == nil, "Do not reinterpret Yazi's relative paths against the project root")

    local mappings = {}
    local function collect(entries)
        for _, entry in ipairs(entries) do
            if type(entry) == "table" then
                if type(entry[1]) == "string" then mappings[entry[1]] = entry[2] end
                collect(entry)
            end
        end
    end
    package.loaded["which-key"] = { add = collect, setup = function() end }
    package.loaded.conform = {}
    package.loaded.treesj = { join = function() end, split = function() end, toggle = function() end }
    package.loaded["snacks.picker"] = { util = { visual = function() return { text = "needle" } end } }
    package.loaded.yazi = { yazi = function(_, path) called = path end }
    dofile(repo .. "/dot_config/nvim/lua/plugins/which-key.lua").config()
    mappings["<leader>E"]()
    assert(called == common.get_cwd())
    mappings["<leader><leader>e"]()
    assert(called.cwd == common.get_cwd())
    for _, key in ipairs({ "<leader>f", "<leader>g" }) do
        mappings[key]()
        assert(called.cwd == common.get_cwd() and called.ignored == false, "Visual " .. key)
    end
    package.loaded.neotest = { run = { run = function(path) called = path end } }
    for _, key in ipairs(dofile(repo .. "/dot_config/nvim/lua/plugins/neotest.lua")[1].keys) do
        if key[1] == "<leader>na" then key[2]() end
    end
    assert(called == common.get_cwd())
    print("Passed project roots, worktree/submodule boundaries, fallback, and consumer checks")

    if vim.env.NVIM_TEST_PLUGINS == "1" then
        package.loaded["snacks.picker"] = nil
        vim.opt.runtimepath:prepend(vim.fn.stdpath("data") .. "/lazy/snacks.nvim")
        local real_snacks = require("snacks")
        real_snacks.config.picker = config
        buffer("repo/src/file.lua")
        write("repo/.gitignore", { "build/" })
        write("repo/visible.txt", { "needle" })
        write("repo/.env.example", { "needle" })
        write("repo/build/generated.txt", { "needle" })
        -- Capture the actual locked Snacks finder's command, then execute it.
        package.loaded["snacks.picker.source.proc"] = { proc = function(opts) return opts end }
        for _, source in ipairs({ "files", "grep" }) do
            for _, ignored in ipairs({ false, true }) do
                local opts = real_snacks.picker.config.get({ source = source, ignored = ignored })
                assert(opts.cwd == tmp .. "/repo")
                local ctx = {
                    filter = { search = source == "grep" and "needle" or "" },
                    opts = function(_, extra) return vim.tbl_extend("force", opts, extra) end,
                }
                local proc = require("snacks.picker.source." .. source)[source](opts, ctx)
                local command = { proc.cmd }
                vim.list_extend(command, proc.args)
                local result = vim.system(command, { cwd = proc.cwd, text = true }):wait()
                assert(result.code == 0, result.stderr)
                assert(result.stdout:find("visible.txt", 1, true))
                assert(result.stdout:find(".env.example", 1, true))
                assert((result.stdout:find("build/generated.txt", 1, true) ~= nil) == ignored)
                assert(not result.stdout:find(".git/config", 1, true))
            end
        end
        print("Passed locked Snacks/ripgrep root, hidden-file, and ignore behavior checks")
    end
end, debug.traceback)
vim.cmd("cd " .. vim.fn.fnameescape(repo))
vim.fn.delete(tmp, "rf")
if not ok then error(err) end
