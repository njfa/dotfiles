local status_ok, vscode = pcall(require, "vscode")

local function vscode_mapping(function_native, function_vscode)
    if status_ok then
        return function_vscode
    end

    return function_native
end

vim.keymap.set("n", "<C-h>", vscode_mapping("<cmd>BufferLineCyclePrev<cr>", "<cmd>Tabprevious<cr>"), { desc = "前のバッファに移動" })
vim.keymap.set("n", "<C-l>", vscode_mapping("<cmd>BufferLineCycleNext<cr>", "<cmd>Tabnext<cr>"), { desc = "次のバッファに移動" })

vim.keymap.set("n", "Q", function()
    local count = vim.v.count
    vim.cmd("normal! " .. (count > 0 and count or "") .. "Q")
    if count > 0 then
        vim.cmd("normal! 1q=")
    end
end, { desc = "マルチカーソル追加（検索時はfollow mode有効）" })
