local M = {}

-- すべてのハイライトグループから特定の色を検索して置き換える
function M.replace_color(old_color, new_color)
    -- 色を正規化（#付きの6桁形式に）
    local function normalize_color(color)
        color = color:lower()
        if not color:match("^#") then
            color = "#" .. color
        end
        return color
    end

    old_color = normalize_color(old_color)
    new_color = normalize_color(new_color)

    local replaced_count = 0

    -- すべてのハイライトグループを取得
    local all_highlights = vim.api.nvim_get_hl(0, {})

    for hl_name, hl_def in pairs(all_highlights) do
        local modified = false
        local new_hl_def = vim.deepcopy(hl_def)

        -- foreground色をチェック
        if hl_def.fg then
            local fg_color = string.format("#%06x", hl_def.fg)
            if fg_color:lower() == old_color then
                new_hl_def.fg = tonumber(new_color:sub(2), 16)
                modified = true
            end
        end

        -- background色をチェック
        if hl_def.bg then
            local bg_color = string.format("#%06x", hl_def.bg)
            if bg_color:lower() == old_color then
                new_hl_def.bg = tonumber(new_color:sub(2), 16)
                modified = true
            end
        end

        -- special色をチェック
        if hl_def.sp then
            local sp_color = string.format("#%06x", hl_def.sp)
            if sp_color:lower() == old_color then
                new_hl_def.sp = tonumber(new_color:sub(2), 16)
                modified = true
            end
        end

        -- 変更があった場合はハイライトを更新
        if modified then
            vim.api.nvim_set_hl(0, hl_name, new_hl_def)
            replaced_count = replaced_count + 1
        end
    end

    print(string.format("Replaced %d highlight groups from %s to %s", replaced_count, old_color, new_color))
end

-- 特定の色を使用しているハイライトグループを検索
function M.find_color(color)
    color = color:lower()
    if not color:match("^#") then
        color = "#" .. color
    end

    local results = {
        fg = {},
        bg = {},
        sp = {}
    }

    local all_highlights = vim.api.nvim_get_hl(0, {})

    for hl_name, hl_def in pairs(all_highlights) do
        -- foreground色をチェック
        if hl_def.fg then
            local fg_color = string.format("#%06x", hl_def.fg)
            if fg_color:lower() == color then
                table.insert(results.fg, hl_name)
            end
        end

        -- background色をチェック
        if hl_def.bg then
            local bg_color = string.format("#%06x", hl_def.bg)
            if bg_color:lower() == color then
                table.insert(results.bg, hl_name)
            end
        end

        -- special色をチェック
        if hl_def.sp then
            local sp_color = string.format("#%06x", hl_def.sp)
            if sp_color:lower() == color then
                table.insert(results.sp, hl_name)
            end
        end
    end

    -- 結果を表示
    print("Highlight groups using " .. color .. ":")
    if #results.fg > 0 then
        print("  Foreground: " .. table.concat(results.fg, ", "))
    end
    if #results.bg > 0 then
        print("  Background: " .. table.concat(results.bg, ", "))
    end
    if #results.sp > 0 then
        print("  Special: " .. table.concat(results.sp, ", "))
    end

    return results
end

-- 色の置き換えを設定ファイルとして保存
function M.save_color_overrides(filename)
    filename = filename or vim.fn.stdpath("config") .. "/lua/color-overrides.lua"

    local lines = {"-- Auto-generated color overrides", "return function()"}
        local all_highlights = vim.api.nvim_get_hl(0, {})

        for hl_name, hl_def in pairs(all_highlights) do
            local attrs = {}

            if hl_def.fg then
                table.insert(attrs, string.format("fg = '#%06x'", hl_def.fg))
            end
            if hl_def.bg then
                table.insert(attrs, string.format("bg = '#%06x'", hl_def.bg))
            end
            if hl_def.sp then
                table.insert(attrs, string.format("sp = '#%06x'", hl_def.sp))
            end
            if hl_def.bold then
                table.insert(attrs, "bold = true")
            end
            if hl_def.italic then
                table.insert(attrs, "italic = true")
            end
            if hl_def.underline then
                table.insert(attrs, "underline = true")
            end

            if #attrs > 0 then
                table.insert(lines, string.format("    vim.api.nvim_set_hl(0, '%s', { %s })", hl_name, table.concat(attrs, ", ")))
            end
        end

        table.insert(lines, "end")

        local file = io.open(filename, "w")
        if file then
            file:write(table.concat(lines, "\n"))
            file:close()
            print("Color overrides saved to: " .. filename)
        else
            print("Error: Could not save to " .. filename)
        end
    end

    return M
