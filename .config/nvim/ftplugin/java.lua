if vim.fn.search("^\t", "nw") == 0 then
    vim.opt_local.expandtab = true
else
    vim.opt_local.expandtab = false
end

if require('common').is_floating_window() then
    return false
end

local status_ok, jdtls = pcall(require, "jdtls")
if not status_ok then
    vim.notify("jdtls is not available", vim.log.levels.WARN)
    return false
end

-- local jdtls = require("jdtls")
local jdtls_dap = require("jdtls.dap")
local jdtls_setup = require("jdtls.setup")
local home = os.getenv("HOME")

local root_markers = { ".git", "mvnw", "gradlew", "pom.xml", "build.gradle" }
local root_dir = jdtls_setup.find_root(root_markers)

local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
local workspace_dir = home .. "/.cache/jdtls/workspace/" .. project_name

local path_to_java17 = vim.fn.glob(home .. "/.sdkman/candidates/java/17.*-amzn/", true)
local path_to_java11 = vim.fn.glob(home .. "/.sdkman/candidates/java/11.*-amzn/", true)

local path_to_mason_packages = vim.fn.stdpath('data') .. "/mason/packages"

local path_to_jdtls = path_to_mason_packages .. "/jdtls"
local path_to_jdebug = path_to_mason_packages .. "/java-debug-adapter"
local path_to_jtest = path_to_mason_packages .. "/java-test"

local path_to_config = path_to_jdtls .. "/config_linux"
local lombok_path = path_to_jdtls .. "/lombok.jar"

local path_to_jar = vim.fn.glob(path_to_jdtls .. "/plugins/org.eclipse.equinox.launcher_*.jar", true)

local bundles = {
    vim.fn.glob(path_to_jdebug .. "/extension/server/com.microsoft.java.debug.plugin-*.jar", true),
}

vim.list_extend(bundles, vim.split(vim.fn.glob(path_to_jtest .. "/extension/server/*.jar", true), "\n"))


-- LSP settings for Java.
local on_attach = function(client, bufnr)
    jdtls.setup_dap({ hotcodereplace = "auto" })
    jdtls_dap.setup_dap_main_class_configs()
    jdtls_setup.add_commands()

    require('common').on_attach_lsp(client, bufnr, "nvim-jdtls")
    local wk = require("which-key")
    wk.register({
        m = {
            name = "LSP",
            i  = { "<Cmd>lua require('jdtls').organize_imports()<CR>", "Organize imports" },
            e = {
                name = "Extract variables / constant",
                v = { "<Cmd>lua require('jdtls').extract_variable()<CR>", "Extract variables" },
                c = { "<Cmd>lua require('jdtls').extract_constant()<CR>", "Extract constant" },
            },
        },
    }, {
        mode = "n",
        buffer = bufnr
    })

    -- local buf_map = require('common').buf_map
    -- local opts = {silent = false, noremap = true}
    -- buf_map(bufnr, "n", "[i", "<Cmd>lua require('jdtls').organize_imports()<CR>", opts)
    -- buf_map(bufnr, "n", "[ev", "<Cmd>lua require('jdtls').extract_variable()<CR>", opts)
    -- buf_map(bufnr, "n", "[ec", "<Cmd>lua require('jdtls').extract_constant()<CR>", opts)

    -- NOTE: comment out if you don't use Lspsaga
    -- require("lspsaga").init_lsp_saga()
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
    path_to_java17 .. 'bin/java', -- or '/path/to/java17_or_newer/bin/java'
    -- depends on if `java` is in your $PATH env variable and if it points to the right version.

    "-Declipse.application=org.eclipse.jdt.ls.core.id1",
    "-Dosgi.bundles.defaultStartLevel=4",
    "-Declipse.product=org.eclipse.jdt.ls.core.product",
    "-Dlog.protocol=true",
    "-Dlog.level=ALL",
    "-Xmx1g",
    "-javaagent:" .. lombok_path,
    "--add-modules=ALL-SYSTEM",
    "--add-opens",
    "java.base/java.util=ALL-UNNAMED",
    "--add-opens",
    "java.base/java.lang=ALL-UNNAMED",
    "-jar",
    path_to_jar,
    "-configuration",
    path_to_config,
    "-data",
    workspace_dir,
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
            runtimes = {
                {
                    name = "JavaSE-11",
                    path = path_to_java11
                },
                {
                    name = "JavaSE-17",
                    path = path_to_java17
                }
            }
        }
    }
}

config.on_attach = on_attach
config.capabilities = capabilities
config.on_init = function(client, _)
    client.notify('workspace/didChangeConfiguration', { settings = config.settings })
end

local extendedClientCapabilities = require 'jdtls'.extendedClientCapabilities
extendedClientCapabilities.resolveAdditionalTextEditsSupport = true

config.init_options = {
    bundles = bundles,
    extendedClientCapabilities = extendedClientCapabilities,
}

-- Start Server
require('jdtls').start_or_attach(config)

-- local jdtls_path = vim.fn.stdpath('data') .. "/mason/packages/jdtls/bin/jdtls"
-- local java_debugger_path = vim.fn.stdpath('data') .. "/mason/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar"


-- local cfg = {
--     cmd = { jdtls_path },
--     root_dir = vim.fs.dirname(vim.fs.find({'gradlew', '.git', 'mvnw', "pom.xml", "build.gradle"}, { upward = true })[1]),
--     init_options = {
--         bundles = {
--             vim.fn.glob(java_debugger_path, true)
--         };
--     },
--     on_attach = function(client, bufnr)
--         -- require('jdtls').setup_dap({ hotcodereplace = 'auto' })
--         on_attach_lsp(client, bufnr)
--     end
-- }

-- require('jdtls').start_or_attach(cfg)

-- require('dap').configurations.java = {
--     {
--         type = 'java';
--         request = 'launch';
--         name = "Debug (Attach) - Remote";
--         hostName = '127.0.0.1';
--         port = 5005;
--     },
-- }
--
