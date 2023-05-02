local M = {}

function M.load(use)
    use {
        'mfussenegger/nvim-jdtls',
        requires = {
            'williamboman/mason.nvim',
        },
        ft = {
            "java"
        },
        config = function ()
            local jdtls_path = vim.fn.stdpath('data') .. "/mason/packages/jdtls/bin/jdtls"
            local java_debugger_path = vim.fn.stdpath('data') .. "/mason/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar"

            local cfg = {
                cmd = { jdtls_path },
                root_dir = vim.fs.dirname(vim.fs.find({'gradlew', '.git', 'mvnw'}, { upward = true })[1]),
                init_options = {
                    bundles = {
                        vim.fn.glob(java_debugger_path, 1)
                    };
                },
                on_attach = function(client, bufnr)
                    require('jdtls').setup_dap({ hotcodereplace = 'auto' })
                end
            }

            require('jdtls').start_or_attach(cfg)

            require('dap').configurations.java = {
                {
                    type = 'java';
                    request = 'launch';
                    name = "Debug (Attach) - Remote";
                    hostName = 'localhost';
                    port = 8080;
                },
            }
        end
    }
end

return M;
