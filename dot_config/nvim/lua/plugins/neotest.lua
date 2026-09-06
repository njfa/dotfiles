local vscode_enabled = pcall(require, "vscode")

local function neotest()
    return require("neotest")
end

local function java_binaries()
    local Path = require("neotest-java.model.path")
    local java = require("java_runtime").resolve()
    local javap = vim.fs.joinpath(
        vim.fs.dirname(java),
        vim.fn.has("win32") == 1 and "javap.exe" or "javap"
    )
    assert(vim.fn.executable(javap) == 1, "NeotestにはJDKのjavapが必要です: " .. javap)

    return {
        java = function()
            return Path(java)
        end,
        javap = function()
            return Path(javap)
        end,
    }
end

local function maven_command(base_dir)
    local windows = vim.fn.has("win32") == 1
    if vim.env.NEOTEST_MAVEN then
        assert(vim.fn.executable(vim.env.NEOTEST_MAVEN) == 1,
            "NEOTEST_MAVENを実行できません: " .. vim.env.NEOTEST_MAVEN)
        return windows and { "cmd.exe", "/D", "/S", "/C", vim.env.NEOTEST_MAVEN }
            or { vim.env.NEOTEST_MAVEN }
    end
    local wrapper = vim.fs.find(windows and { "mvnw.cmd", "mvnw" } or { "mvnw" }, {
        path = base_dir,
        upward = true,
        type = "file",
    })[1]
    if not wrapper then
        return windows and { "cmd.exe", "/D", "/S", "/C", "mvn.cmd" } or { "mvn" }
    end
    if windows then
        return { "cmd.exe", "/D", "/S", "/C", wrapper }
    end
    return vim.fn.executable(wrapper) == 1 and { wrapper } or { "sh", wrapper }
end

local function pom_fingerprint(base_dir)
    local root = require("java_root").find_root(vim.fs.joinpath(base_dir, "pom.xml")) or base_dir
    local parts = {}
    local dir = base_dir
    while dir do
        local stat = vim.uv.fs_stat(vim.fs.joinpath(dir, "pom.xml"))
        if stat then
            table.insert(parts, table.concat({ dir, stat.size, stat.mtime.sec, stat.mtime.nsec }, ":"))
        end
        if dir == root then
            break
        end
        local parent = vim.fs.dirname(dir)
        if parent == dir then
            break
        end
        dir = parent
    end
    return table.concat(parts, "|")
end

local function java_classpath_provider()
    local default_provider = require("neotest-java.core.spec_builder.compiler.classpath_provider")({
        client_provider = require("neotest-java.core.spec_builder.compiler").client_provider,
    })
    local cache = {}
    local separator = vim.fn.has("win32") == 1 and ";" or ":"

    return {
        get_classpath = function(base_dir, additional_entries)
            local module_dir = base_dir:to_string()
            local pom = vim.fs.joinpath(module_dir, "pom.xml")
            if not vim.uv.fs_stat(pom) then
                return default_provider.get_classpath(base_dir, additional_entries)
            end

            local fingerprint = pom_fingerprint(module_dir)
            local dependencies = cache[module_dir]
            if not dependencies or dependencies.fingerprint ~= fingerprint then
                local nio = require("nio")
                local output_file = nio.fn.tempname()
                local command = maven_command(module_dir)
                vim.list_extend(command, {
                    "-q",
                    "-f",
                    pom,
                    "-DincludeScope=test",
                    "-Dmdep.outputFile=" .. output_file,
                    "dependency:build-classpath",
                })

                local completed = nio.control.future()
                local java = require("java_runtime").resolve()
                vim.schedule(function()
                    local ok, err = pcall(vim.system, command, {
                        text = true,
                        env = { JAVA_HOME = vim.fs.dirname(vim.fs.dirname(java)) },
                    }, completed.set)
                    if not ok then
                        completed.set({ code = -1, stderr = tostring(err) })
                    end
                end)
                local result = completed.wait()
                if result.code ~= 0 then
                    nio.fn.delete(output_file)
                    local detail = result.stderr
                    if not detail or detail == "" then
                        detail = result.stdout
                    end
                    if not detail or detail == "" then
                        detail = "終了コード " .. result.code
                    end
                    error(("Mavenのテスト用クラスパスを取得できませんでした:\n%s"):format(
                        detail:sub(-4000)
                    ))
                end
                dependencies = {
                    fingerprint = fingerprint,
                    value = table.concat(nio.fn.readfile(output_file), ""),
                }
                nio.fn.delete(output_file)
                cache[module_dir] = dependencies
            end

            local entries = {
                vim.fs.joinpath(module_dir, "target", "test-classes"),
                vim.fs.joinpath(module_dir, "target", "classes"),
            }
            vim.list_extend(entries, vim.split(dependencies.value, separator, { plain = true, trimempty = true }))
            for _, path in ipairs(additional_entries or {}) do
                table.insert(entries, path:to_string())
            end
            local unique, seen = {}, {}
            for _, entry in ipairs(entries) do
                if entry ~= "" and not seen[entry] then
                    seen[entry] = true
                    table.insert(unique, entry)
                end
            end
            return table.concat(unique, separator)
        end,
    }
end

local function java_build_tool_getter(project_type)
    local tool = require("neotest-java.build_tool").get(project_type)
    -- Adding every module's Spring configuration lets one microservice override
    -- another. Each module already exposes its resources through its classpath.
    return vim.tbl_extend("force", tool, {
        get_spring_property_filepaths = function()
            return {}
        end,
    })
end

return {
    {
        "nvim-neotest/neotest",
        cond = not vscode_enabled,
        dependencies = {
            "nvim-neotest/nvim-nio",
            "nvim-lua/plenary.nvim",
            "antoinemadec/FixCursorHold.nvim",
            "nvim-treesitter/nvim-treesitter",
            {
                "rcasia/neotest-java",
                cmd = "NeotestJava",
                dependencies = {
                    "mfussenegger/nvim-jdtls",
                    "mfussenegger/nvim-dap",
                },
                build = function()
                    -- The upstream installer asks before downloading the checksum-pinned
                    -- JUnit runner. Plugin installation already expresses that intent.
                    local original_select = vim.ui.select
                    vim.ui.select = function(items, _, callback)
                        callback(items[1])
                    end
                    local ok, err = xpcall(function()
                        require("neotest-java").install()
                    end, debug.traceback)
                    vim.ui.select = original_select
                    if not ok then
                        error(err)
                    end
                end,
            },
            "nvim-neotest/neotest-python",
            "fredrikaverpil/neotest-golang",
        },
        keys = {
            {
                "<leader>nn",
                function()
                    neotest().run.run()
                end,
                desc = "最寄りのテストを実行",
            },
            {
                "<leader>nf",
                function()
                    neotest().run.run(vim.fn.expand("%"))
                end,
                desc = "現在のファイルのテストを実行",
            },
            {
                "<leader>na",
                function()
                    neotest().run.run(vim.uv.cwd())
                end,
                desc = "プロジェクトのテストを実行",
            },
            {
                "<leader>nl",
                function()
                    neotest().run.run_last()
                end,
                desc = "直前のテストを再実行",
            },
            {
                "<leader>nd",
                function()
                    neotest().run.run({ suite = false, strategy = "dap" })
                end,
                desc = "最寄りのテストをデバッグ",
            },
            {
                "<leader>nD",
                function()
                    neotest().run.run({ vim.fn.expand("%"), strategy = "dap" })
                end,
                desc = "現在のファイルのテストをデバッグ",
            },
            {
                "<leader>ns",
                function()
                    neotest().summary.toggle()
                end,
                desc = "テスト一覧を表示",
            },
            {
                "<leader>no",
                function()
                    neotest().output.open({ enter = true, auto_close = true })
                end,
                desc = "最寄りのテスト結果を表示",
            },
            {
                "<leader>nO",
                function()
                    neotest().output_panel.toggle()
                end,
                desc = "テスト出力パネルを表示",
            },
            {
                "<leader>nx",
                function()
                    neotest().run.stop()
                end,
                desc = "テストを停止",
            },
        },
        config = function()
            require("neotest").setup({
                adapters = {
                    require("neotest-java")({
                        jvm_args = { "-Xmx512m" },
                        incremental_build = true,
                    }, {
                        -- Aggregator POMs are not Java projects in JDTLS. Resolve the
                        -- binaries from the same configured JDK instead of querying
                        -- java.project.getSettings for an aggregator project.
                        binaries = java_binaries(),
                        -- JDTLS/m2e may associate a module classpath request with its
                        -- non-Java aggregator project. Maven resolves the module's
                        -- test classpath reliably; Gradle keeps the upstream provider.
                        classpath_provider = java_classpath_provider(),
                        build_tool_getter = java_build_tool_getter,
                    }),
                    require("neotest-python")({
                        runner = "pytest",
                        python = function()
                            return require("debugging").python()
                        end,
                        dap = { justMyCode = false },
                    }),
                    require("neotest-golang")({
                        runner = "gotestsum",
                        go_test_args = { "-v", "-count=1" },
                        dap_mode = "manual",
                        dap_manual_config = function()
                            -- The adapter appends test arguments to this table.
                            -- Return a fresh value so repeated debug runs do not accumulate them.
                            return {
                                name = "Goテストをデバッグ",
                                type = "go",
                                request = "launch",
                                mode = "test",
                            }
                        end,
                    }),
                },
                discovery = {
                    concurrent = 1,
                },
                running = {
                    concurrent = false,
                },
                output = {
                    open_on_run = "short",
                },
                quickfix = {
                    open = false,
                },
                status = {
                    virtual_text = false,
                },
            })
        end,
    },
}
