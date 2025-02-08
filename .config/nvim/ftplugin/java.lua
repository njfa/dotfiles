if vim.fn.search("^\t", "nw") == 0 then
    vim.opt_local.expandtab = true
else
    vim.opt_local.expandtab = false
end

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

if require('common').is_floating_window() then
    return false
end

local status_ok, jdtls = pcall(require, "jdtls")
if not status_ok then
    vim.notify("jdtls is not available", vim.log.levels.WARN)
    return false
end

-- local jdtls_dap = require("jdtls.dap")
local jdtls_setup = require("jdtls.setup")
local home = os.getenv("HOME")

local root_markers = { ".git" }
local root_dir = jdtls_setup.find_root(root_markers)
if root_dir then
    vim.notify("jdtls root dir: " .. root_dir, vim.log.levels.INFO)
else
    vim.notify("jdtls root dir is nil", vim.log.levels.INFO)
end



local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
local workspace_dir = home .. "/.cache/jdtls/workspace/" .. project_name

local jdk_runtimes = {}
local path_to_java21 = vim.fn.glob(home .. "/.sdkman/candidates/java/21.*-amzn/", true, true)[1]
if path_to_java21 ~= "" then
    table.insert(jdk_runtimes, {
        name = "JavaSE-21",
        path = path_to_java21
    })
end

local path_to_java17 = vim.fn.glob(home .. "/.sdkman/candidates/java/17.*-amzn/", true, true)[1]
if path_to_java17 ~= "" then
    table.insert(jdk_runtimes, {
        name = "JavaSE-17",
        path = path_to_java17
    })
end

local path_to_java11 = vim.fn.glob(home .. "/.sdkman/candidates/java/11.*-amzn/", true, true)[1]
if path_to_java11 ~= "" then
    table.insert(jdk_runtimes, {
        name = "JavaSE-11",
        path = path_to_java11
    })
end

local path_to_java8 = vim.fn.glob(home .. "/.sdkman/candidates/java/8.*-amzn/", true, true)[1]
if path_to_java8 ~= "" then
    table.insert(jdk_runtimes, {
        name = "JavaSE-1.8",
        path = path_to_java8
    })
end

local path_to_mason_packages = vim.fn.stdpath('data') .. "/mason/packages"

local path_to_openjdk17 = vim.fn.glob(path_to_mason_packages .. "/openjdk-17/jdk-17.*/", true)
local path_to_openjdk21 = vim.fn.glob(path_to_mason_packages .. "/openjdk-21/jdk-21.*/", true)
local path_to_jdtls = path_to_mason_packages .. "/jdtls"
local path_to_jdebug = path_to_mason_packages .. "/java-debug-adapter"
local path_to_jtest = path_to_mason_packages .. "/java-test"
local path_to_jdecompiler = path_to_mason_packages .. "/vscode-java-decompiler"

local path_to_config = path_to_jdtls .. '/' .. get_config_dir()
local path_to_lombok = path_to_mason_packages .. "/lombok-nightly/lombok.jar"

local path_to_jar = vim.fn.glob(path_to_jdtls .. "/plugins/org.eclipse.equinox.launcher_*.jar", true)

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
    jdtls.setup_dap({ hotcodereplace = "auto" })
    -- jdtls_dap.setup_dap_main_class_configs()
    jdtls_setup.add_commands()

    require('common').on_attach_lsp(client, bufnr, "nvim-jdtls")
    local wk = require("which-key")

    wk.add({
        {
            mode = { "n" },
            buffer = bufnr,

            { "mi",  "<Cmd>lua require('jdtls').organize_imports()<CR>", desc = "Organize imports" },
            { "mev", "<Cmd>lua require('jdtls').extract_variable()<CR>", desc = "Extract variables" },
            { "mec", "<Cmd>lua require('jdtls').extract_constant()<CR>", desc = "Extract constant" },
        }
    })
end

local capabilities = {
    workspace = {
        configuration = true
    },
    textDocument = {
        completion = {
            completionItem = {
                snippetSupport = true
            }
        }
    }
}
-- local capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())

local config = {
    flags = {
        allow_incremental_sync = true,
    }
}

config.cmd = {
    path_to_openjdk21 .. 'bin/java', -- or '/path/to/java17_or_newer/bin/java'
    -- depends on if `java` is in your $PATH env variable and if it points to the right version.

    "-Declipse.application=org.eclipse.jdt.ls.core.id1",
    "-Dosgi.bundles.defaultStartLevel=4",
    "-Declipse.product=org.eclipse.jdt.ls.core.product",
    "-Dlog.protocol=true",
    "-Dlog.level=ALL",
    "-Xmx2g",
    "-javaagent:" .. path_to_lombok,
    "--add-modules=ALL-SYSTEM",
    "--add-opens", "java.base/java.util=ALL-UNNAMED",
    "--add-opens", "java.base/java.lang=ALL-UNNAMED",
    "-jar", path_to_jar,
    "-configuration", path_to_config,
    "-data", workspace_dir,
}

config.settings = {
    java = {
        references = {
            includeDecompiledSources = true,
        },
        eclipse = {
            downloadSources = true,
        },
        maven = {
            downloadSources = true,
        },
        signatureHelp = { enabled = true },
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
            runtimes = jdk_runtimes
        }
    }
}

config.on_attach = on_attach
config.capabilities = capabilities
config.on_init = function(client, _)
    client.notify('workspace/didChangeConfiguration', { settings = config.settings })
end

local extendedClientCapabilities = require('jdtls').extendedClientCapabilities
extendedClientCapabilities.resolveAdditionalTextEditsSupport = true

config.init_options = {
    bundles = bundles,
    extendedClientCapabilities = extendedClientCapabilities
}
config.root_dir = root_dir

-- Start Server
require('jdtls').start_or_attach(config)
