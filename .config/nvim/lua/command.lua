local function set_numbering(lines, cursor_line)
    local numbering = { 0, 0, 0, 0, 0, 0 }
    local level = 0
    local start_line = nil
    local in_code_block = false

    -- Reset in_code_block state
    for i = 1, cursor_line do
        if lines[i]:match("^```") then
            in_code_block = not in_code_block
        end
    end

    -- Find the start line of the current header
    for i = cursor_line, 1, -1 do
        if lines[i]:match("^```") then
            in_code_block = not in_code_block
        elseif not in_code_block and lines[i]:match("^#+") then
            start_line = i
            level = #lines[i]:match("^#+")
            break
        end
    end

    if not start_line then return lines end

    -- Apply numbering to the current header section
    for i = start_line, #lines do
        if lines[i]:match("^```") then
            in_code_block = not in_code_block
        elseif not in_code_block then
            local header_level = lines[i]:match("^#+")
            if header_level then
                local current_level = #header_level
                if current_level < level then
                    break
                else
                    for j = current_level + 1, 6 do
                        numbering[j] = 0
                    end

                    numbering[current_level] = numbering[current_level] + 1
                    local numbering_str = table.concat(numbering, ".", level, current_level)
                    lines[i] = lines[i]:gsub("^#+%s*[%d+%.]*%s*", header_level .. " " .. numbering_str .. ". ")
                end
            end
        end
    end
    return lines
end

local function unset_numbering(lines, cursor_line)
    local in_code_block = false

    -- Reset in_code_block state
    for i = 1, cursor_line do
        if lines[i]:match("^```") then
            in_code_block = not in_code_block
        end
    end

    -- Find the start line of the current header
    local start_line = nil
    for i = cursor_line, 1, -1 do
        if lines[i]:match("^```") then
            in_code_block = not in_code_block
        elseif not in_code_block and lines[i]:match("^#+") then
            start_line = i
            break
        end
    end

    if not start_line then return lines end

    -- Remove numbering from the current header section
    for i = start_line, #lines do
        if lines[i]:match("^```") then
            in_code_block = not in_code_block
        elseif not in_code_block then
            local header_level = lines[i]:match("^#+")
            if header_level then
                lines[i] = lines[i]:gsub("^(#+)%s*[%d+%.]*%s*", "%1 ")
            end
        end
    end
    return lines
end

local function toggle_numbering(lines, cursor_line)
    local has_numbers = false

    -- Check if current section has numbers
    for i = cursor_line, 1, -1 do
        if lines[i]:match("^#+%s*%d+%.") then
            has_numbers = true
            break
        elseif lines[i]:match("^#+") then
            break
        end
    end

    if has_numbers then
        print('has number')
        return unset_numbering(lines, cursor_line)
    else
        print('does not have number')
        return set_numbering(lines, cursor_line)
    end
end

vim.api.nvim_create_user_command("SetHeaderNumber", function()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local cursor_line = cursor_pos[1]
    local new_lines = set_numbering(lines, cursor_line)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, new_lines)
end, {})

vim.api.nvim_create_user_command("UnsetHeaderNumber", function()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local cursor_line = cursor_pos[1]
    local new_lines = unset_numbering(lines, cursor_line)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, new_lines)
end, {})

vim.api.nvim_create_user_command("ToggleHeaderNumber", function()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local cursor_line = cursor_pos[1]
    local new_lines = toggle_numbering(lines, cursor_line)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, new_lines)
end, {})
