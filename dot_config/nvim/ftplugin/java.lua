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

-- local jdtls_dap = require("jdtls.dap")
local jdtls_setup = require("jdtls.setup")
local home = os.getenv("HOME")

local function first_glob(pattern)
    local matches = vim.fn.glob(pattern, true, true)
    return matches[1]
end

local function normalize_dir(path)
    return vim.fn.fnamemodify(path, ":p"):gsub("/$", "")
end

local function dirname(path)
    return vim.fn.fnamemodify(path, ":p:h")
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
    local ok, lines = pcall(vim.fn.readfile, pom_path, "", 200)
    if not ok then
        return false
    end

    return vim.iter(lines):any(function(line)
        return line:match("<modules>") ~= nil
    end)
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
local current_file_dir = dirname(vim.api.nvim_buf_get_name(0))
local git_root = jdtls_setup.find_root({ ".git" })
local explicit_root = find_upwards(current_file_dir, ".jdtls-root", git_root)
local aggregator_root = find_topmost_aggregator_pom(current_file_dir, git_root)
local root_dir = explicit_root or aggregator_root or jdtls_setup.find_root(root_markers)
if not root_dir then
    return
end
if not require('common').is_floating_window() and root_dir then
    vim.notify("jdtls root dir: " .. root_dir, vim.log.levels.INFO)
end

local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
local root_hash = vim.fn.sha256(vim.fn.fnamemodify(root_dir, ":p")):sub(1, 12)
local workspace_dir = home .. "/.cache/jdtls/workspace/" .. project_name .. "-" .. root_hash

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

local path_to_openjdk21 = first_glob(path_to_mason_packages .. "/openjdk-21/jdk-21.*/")
local path_to_jdtls = path_to_mason_packages .. "/jdtls"
local path_to_jdebug = path_to_mason_packages .. "/java-debug-adapter"
local path_to_jtest = path_to_mason_packages .. "/java-test"
local path_to_jdecompiler = path_to_mason_packages .. "/vscode-java-decompiler"

local path_to_config = path_to_jdtls .. '/' .. get_config_dir()
local path_to_lombok = path_to_mason_packages .. "/lombok-nightly/lombok.jar"

local path_to_jar = vim.fn.glob(path_to_jdtls .. "/plugins/org.eclipse.equinox.launcher_*.jar", true)
if path_to_jar == "" or vim.fn.isdirectory(path_to_config) == 0 then
    vim.notify("jdtls is not installed correctly", vim.log.levels.WARN)
    return
end

local jar_patterns = {
    path_to_jdebug .. "/extension/server/com.microsoft.java.debug.plugin-*.jar",
    path_to_jtest .. "/extension/server/*.jar",
    path_to_jdecompiler .. '/server/*.jar',
}

local bundles = {}
for _, jar_pattern in ipairs(jar_patterns) do
    for _, bundle in ipairs(vim.split(vim.fn.glob(jar_pattern), '\n')) do
        if not vim.endswith(bundle, 'com.microsoft.java.test.runner-jar-with-dependencies.jar')
            and not vim.endswith(bundle, 'com.microsoft.java.test.runner.jar')
            and string.find(bundle, 'junit-platform-commons', 1, true) == nil
            and string.find(bundle, 'org.apiguardian.api', 1, true) == nil
            and string.find(bundle, 'junit-platform-engine', 1, true) == nil
            and string.find(bundle, 'junit-platform-launcher', 1, true) == nil
            and string.find(bundle, 'org.opentest4j', 1, true) == nil
        then
            table.insert(bundles, bundle)
        end
    end
end

-- LSP settings for Java.
local on_attach = function(client, bufnr)
    client.server_capabilities.typeDefinitionProvider = false

    jdtls.setup_dap({ hotcodereplace = "auto" })
    -- jdtls_dap.setup_dap_main_class_configs()
    jdtls_setup.add_commands()

    require('common').on_attach_lsp(client, bufnr)
    local wk = require("which-key")

    wk.add({
        {
            mode = { "n" },
            buffer = bufnr,

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
    })
end

local capabilities = require("blink.cmp").get_lsp_capabilities(vim.lsp.protocol.make_client_capabilities())
capabilities.workspace.configuration = true
capabilities.textDocument.completion.completionItem.snippetSupport = true

local config = {
    capabilities = capabilities,
    on_attach = not require('common').is_floating_window() and on_attach or nil
}

-- マルチモジュールの初回インポートでjdtlsが全コアを使い切りPC全体が固まるため、
-- 使用コア数を物理コアの半分(最低2)に制限し、プロセス優先度も下げる
local cpu_count = #vim.uv.cpu_info()
local jdtls_cpu_limit = math.max(2, math.floor(cpu_count / 2))

config.cmd = {}

if vim.fn.executable("nice") == 1 then
    vim.list_extend(config.cmd, { "nice", "-n", "10" })
end

vim.list_extend(config.cmd, {
    path_to_openjdk21 and (path_to_openjdk21 .. 'bin/java') or 'java', -- or '/path/to/java17_or_newer/bin/java'
    -- depends on if `java` is in your $PATH env variable and if it points to the right version.

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
    "-Xmx2g",
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
