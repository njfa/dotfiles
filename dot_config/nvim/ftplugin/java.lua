if vim.fn.search("^\t", "nw") == 0 then
    vim.opt_local.expandtab = true
else
    vim.opt_local.expandtab = false
end

vim.g.java_ignore_markdown = 1

local function get_config_dir()
    -- Unlike some other programming languages (e.g. JavaScript)
    -- lua considers 0 truthy!
    if vim.fn.has('linux') == 1 then
        return 'config_linux'
    elseif vim.fn.has('mac') == 1 then
        return 'config_mac'
    else
        return 'config_win'
    end
end

local status_ok, jdtls = pcall(require, "jdtls")
if not status_ok then
    vim.notify("jdtls is not available", vim.log.levels.WARN)
    return false
end

-- Bundles are fixed in init_options and take effect after :JdtRestart. JDT LS
-- asks VS Code to refresh its dynamic bundle list even though Neovim has none.
vim.lsp.commands["_java.reloadBundles.command"] = vim.lsp.commands["_java.reloadBundles.command"] or function()
    return vim.NIL
end

local home = vim.uv.os_homedir()

local function first_glob(pattern)
    local matches = vim.fn.glob(pattern, true, true)
    return matches[1]
end

local root_dir = require("java_root").find_root(vim.api.nvim_buf_get_name(0))
if not root_dir then
    return
end
if not require('common').is_floating_window() and root_dir then
    vim.notify("jdtls root dir: " .. root_dir, vim.log.levels.INFO)
end

local project_name = vim.fs.basename(root_dir)
local root_hash = vim.fn.sha256(vim.fn.fnamemodify(root_dir, ":p")):sub(1, 12)
local workspace_dir = vim.fn.stdpath("cache") .. "/jdtls/workspace/" .. project_name .. "-" .. root_hash

local jdk_runtimes = {}
local path_to_java21 = first_glob(home .. "/.sdkman/candidates/java/21.*-amzn/")
if path_to_java21 then
    table.insert(jdk_runtimes, {
        name = "JavaSE-21",
        path = path_to_java21
    })
end

local path_to_java17 = first_glob(home .. "/.sdkman/candidates/java/17.*-amzn/")
if path_to_java17 then
    table.insert(jdk_runtimes, {
        name = "JavaSE-17",
        path = path_to_java17
    })
end

local path_to_java11 = first_glob(home .. "/.sdkman/candidates/java/11.*-amzn/")
if path_to_java11 then
    table.insert(jdk_runtimes, {
        name = "JavaSE-11",
        path = path_to_java11
    })
end

local path_to_java8 = first_glob(home .. "/.sdkman/candidates/java/8.*-amzn/")
if path_to_java8 then
    table.insert(jdk_runtimes, {
        name = "JavaSE-1.8",
        path = path_to_java8
    })
end

local path_to_mason_packages = vim.fn.stdpath('data') .. "/mason/packages"

local runtime = require("java_runtime")
local ok, java, jdtls_cpu_limit, max_heap = pcall(function()
    local executable = runtime.resolve()
    runtime.validate(executable)
    local cpus, heap = runtime.limits()
    return executable, cpus, heap
end)
if not ok then
    vim.notify(java, vim.log.levels.ERROR)
    return
end
jdk_runtimes = vim.g.jdtls_runtimes or jdk_runtimes
local path_to_jdtls = path_to_mason_packages .. "/jdtls"
local path_to_config = path_to_jdtls .. '/' .. get_config_dir()
local path_to_lombok = path_to_mason_packages .. "/lombok-nightly/lombok.jar"

local path_to_jar = first_glob(path_to_jdtls .. "/plugins/org.eclipse.equinox.launcher_*.jar")
if not path_to_jar or vim.fn.isdirectory(path_to_config) == 0 then
    vim.notify("jdtls is not installed correctly", vim.log.levels.WARN)
    return
end

local bundles = require("java_bundles").collect(path_to_mason_packages)
local has_java_debug = vim.iter(bundles):any(function(path)
    return path:find("com.microsoft.java.debug.plugin-", 1, true) ~= nil
end)
if has_java_debug then
    -- Register before LspAttach so nvim-jdtls keeps these options when it adds commands.
    jdtls.setup_dap({ hotcodereplace = "auto" })
end

-- LSP settings for Java.
local on_attach = function(client, bufnr)
    client.server_capabilities.typeDefinitionProvider = false

    local commands = (client.server_capabilities.executeCommandProvider or {}).commands or {}
    if vim.tbl_contains(commands, "vscode.java.startDebugSession") then
        require("dap").providers.configs.jdtls = nil
    else
        vim.notify("Javaデバッグには :MasonInstall java-debug-adapter が必要です。導入後に :JdtRestart", vim.log.levels.WARN)
    end

    local java_mappings = {
        { "mi",  "<Cmd>lua require('jdtls').organize_imports()<CR>", desc = "Organize imports" },
        { "mev", "<Cmd>lua require('jdtls').extract_variable()<CR>", desc = "Extract variables" },
        { "mec", "<Cmd>lua require('jdtls').extract_constant()<CR>", desc = "Extract constant" },
        {
            "mdc",
            -- 起動時に自動実行するとメインクラス走査が走って重いため、launch方式で
            -- デバッグしたいときにオンデマンドで実行する
            function()
                require("jdtls.dap").setup_dap_main_class_configs({ verbose = true })
            end,
            desc = "メインクラスを検出してデバッグ設定を生成",
        },
    }
    if vim.tbl_contains(commands, "vscode.java.test.junit.argument") then
        table.insert(java_mappings, { "mtc", function() jdtls.test_class() end, desc = "テストクラスをデバッグ" })
        table.insert(java_mappings, { "mtn", function() jdtls.test_nearest_method() end, desc = "最寄りのテストをデバッグ" })
    end

    local group = {
        mode = { "n" },
        buffer = bufnr,
    }
    vim.list_extend(group, java_mappings)
    require("which-key").add({ group })
end

local capabilities = require("blink.cmp").get_lsp_capabilities(vim.lsp.protocol.make_client_capabilities())
capabilities.workspace.configuration = true
capabilities.textDocument.completion.completionItem.snippetSupport = true

local config = {
    capabilities = capabilities,
    on_attach = not require('common').is_floating_window() and on_attach or nil
}

-- JVMの並列度を抑える。CPU使用率の強制上限ではない。
config.cmd = {}

if vim.fn.executable("nice") == 1 then
    vim.list_extend(config.cmd, { "nice", "-n", "10" })
end

vim.list_extend(config.cmd, {
    java,

    "-Declipse.application=org.eclipse.jdt.ls.core.id1",
    "-Dosgi.bundles.defaultStartLevel=4",
    "-Declipse.product=org.eclipse.jdt.ls.core.product",
    "-Dlog.protocol=false",
    "-Dlog.level=ERROR",
    "-Dsun.zip.disableMemoryMapping=true",
    -- VS Code Java拡張のデフォルトに合わせたGC設定。スループット重視でGC時間の上限を抑える
    "-XX:+UseParallelGC",
    "-XX:GCTimeRatio=4",
    "-XX:AdaptiveSizePolicyWeight=90",
    "-XX:ActiveProcessorCount=" .. jdtls_cpu_limit,
    "-Xms256m",
    "-Xmx" .. max_heap,
})

if vim.fn.filereadable(path_to_lombok) == 1 then
    table.insert(config.cmd, "-javaagent:" .. path_to_lombok)
end

vim.list_extend(config.cmd, {
    "--add-modules=ALL-SYSTEM",
    "--add-opens", "java.base/java.util=ALL-UNNAMED",
    "--add-opens", "java.base/java.lang=ALL-UNNAMED",
    "-jar", path_to_jar,
    "-configuration", path_to_config,
    "-data", workspace_dir,
})

config.settings = {
    java = {
        references = {
            includeDecompiledSources = true,
        },
        -- 依存ライブラリのsources JARは自動ダウンロードしない(初回インポートの負荷軽減)
        -- ライブラリ実装を読みたいときは `mvn dependency:sources` で手動取得すれば拾われる。
        -- 未取得の依存へのジャンプはfernflowerのデコンパイル結果にフォールバックする
        eclipse = {
            downloadSources = false,
        },
        maven = {
            downloadSources = false,
        },
        import = {
            -- ビルド成果物ディレクトリをプロジェクト探索から除外する
            -- (targetやbuild配下に生成されたpom.xml等を別プロジェクトとして誤認識させない)
            exclusions = {
                "**/node_modules/**",
                "**/.metadata/**",
                "**/archetype-resources/**",
                "**/META-INF/maven/**",
                "**/target/**",
                "**/build/**",
            },
            generatesMetadataFilesAtProjectRoot = false,
        },
        -- 複数モジュールのビルドが並列に走るとCPUを使い切るため直列化する
        maxConcurrentBuilds = 1,
        contentProvider = { preferred = "fernflower" },
        completion = {
            favoriteStaticMembers = {
                "org.hamcrest.MatcherAssert.assertThat",
                "org.hamcrest.Matchers.*",
                "org.hamcrest.CoreMatchers.*",
                "org.junit.jupiter.api.Assertions.*",
                "java.util.Objects.requireNonNull",
                "java.util.Objects.requireNonNullElse",
                "org.mockito.Mockito.*",
            },
            filteredTypes = {
                "com.sun.*",
                "io.micrometer.shaded.*",
                "java.awt.*",
                "jdk.*",
                "sun.*",
            },
            importOrder = {
                "java",
                "javax",
                "com",
                "org",
            },
        },
        sources = {
            organizeImports = {
                starThreshold = 9999,
                staticStarThreshold = 9999,
            },
        },
        codeGeneration = {
            toString = {
                template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
            },
            useBlocks = true,
        },
        configuration = {
            updateBuildConfiguration = "interactive",
            runtimes = jdk_runtimes
        }
    }
}

local extendedClientCapabilities = require('jdtls').extendedClientCapabilities
extendedClientCapabilities.resolveAdditionalTextEditsSupport = true

config.init_options = {
    bundles = bundles,
    extendedClientCapabilities = extendedClientCapabilities,
}
config.root_dir = root_dir

-- Start Server
require('jdtls').start_or_attach(config)
