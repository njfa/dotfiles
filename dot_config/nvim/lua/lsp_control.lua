local M = {}
local policy = require("lsp_policy")
local servers = vim.list_extend(vim.deepcopy(policy.servers), { "null-ls" })
table.sort(servers)
local special_enabled = { jdtls = false, ["null-ls"] = false }

function M.is_enabled(name)
    if special_enabled[name] ~= nil then
        return special_enabled[name]
    end
    return vim.lsp.is_enabled(name)
end

function M.set_enabled(name, enabled)
    if not vim.tbl_contains(servers, name) then
        error("Unknown managed LSP: " .. name .. " (see lsp_policy.lua)")
    end

    if name == "jdtls" then
        special_enabled.jdtls = enabled
        if enabled then
            -- Re-run our ftplugin for buffers already open, without replaying FileType.
            local ftplugin = vim.api.nvim_get_runtime_file("ftplugin/java.lua", false)[1]
            for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].filetype == "java" then
                    vim.api.nvim_buf_call(bufnr, function()
                        dofile(ftplugin)
                    end)
                end
            end
        else
            for _, client in ipairs(vim.lsp.get_clients({ name = "jdtls" })) do
                client:stop()
            end
        end
    elseif name == "null-ls" then
        special_enabled[name] = enabled
        if enabled then
            -- none-ls has its own client lifecycle, independent of vim.lsp.enable.
            local client = package.loaded["null-ls.client"]
            if client then
                for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
                    if vim.api.nvim_buf_is_loaded(bufnr) then
                        vim.api.nvim_buf_call(bufnr, function()
                            client.try_add(bufnr)
                        end)
                    end
                end
            end
        else
            for _, client in ipairs(vim.lsp.get_clients({ name = name })) do
                client:stop()
            end
        end
    else
        -- Disabling also stops running clients and prevents future automatic starts.
        vim.lsp.enable(name, enabled)
    end
end

function M.servers_for_filetype(filetype)
    if filetype == "" then
        return {}
    end
    return vim.tbl_filter(function(name)
        if name == "jdtls" then
            return filetype == "java"
        elseif name == "null-ls" then
            local sources = package.loaded["null-ls.sources"]
            return sources ~= nil and #sources.get_available(filetype) > 0
        end
        local config = vim.lsp.config[name]
        return config ~= nil and vim.tbl_contains(config.filetypes or {}, filetype)
    end, servers)
end

-- Called after Mason/lspconfig setup, when server configurations can be resolved.
function M.apply_defaults()
    for _, name in ipairs(policy.default_enabled) do
        M.set_enabled(name, true)
    end
end

function M.setup()
    -- Java is always started via nvim-jdtls, never the built-in config path.
    vim.lsp.enable(policy.servers, false)
    for _, action in ipairs({ "Enable", "Disable", "Toggle" }) do
        vim.api.nvim_create_user_command("Lsp" .. action, function(opts)
            local targets = { opts.args }
            if opts.args == "" then
                targets = M.servers_for_filetype(vim.bo.filetype)
                if #targets == 0 then
                    vim.notify("手動切替の対象LSPがありません: " .. vim.bo.filetype, vim.log.levels.WARN)
                    return
                end
            end
            -- Mixed states converge to enabled; toggling an all-enabled group disables it.
            local all_enabled = true
            for _, name in ipairs(targets) do
                all_enabled = all_enabled and M.is_enabled(name)
            end
            local enabled = action == "Enable" or (action == "Toggle" and not all_enabled)
            for _, name in ipairs(targets) do
                M.set_enabled(name, enabled)
            end
            vim.notify(table.concat(targets, ", ") .. ": " .. (enabled and "enabled" or "disabled"))
        end, {
            nargs = "?",
            complete = function(prefix)
                return vim.tbl_filter(function(name)
                    return vim.startswith(name, prefix)
                end, servers)
            end,
            desc = action .. " an opt-in LSP for this Neovim session",
        })
    end
    vim.api.nvim_create_user_command("LspStatus", function()
        local lines = {}
        for _, name in ipairs(servers) do
            table.insert(lines, name .. ": " .. (M.is_enabled(name) and "enabled" or "disabled")
                .. " (" .. #vim.lsp.get_clients({ name = name }) .. " clients)")
        end
        vim.notify(table.concat(lines, "\n"))
    end, { desc = "Show opt-in LSP enablement and running client counts" })

    vim.keymap.set("n", "<leader>lt", "<Cmd>LspToggle<CR>", {
        silent = true,
        desc = "ファイルタイプに応じてLSPの有効/無効を切替",
    })
    vim.keymap.set("n", "<leader>.l", "<Cmd>LspToggle<CR>", {
        silent = true,
        desc = "ファイルタイプに応じてLSPの有効/無効を切替",
    })
    vim.keymap.set("n", "<leader>.s", "<Cmd>LspStatus<CR>", {
        silent = true,
        desc = "LSPの有効状態を確認",
    })
end

return M
