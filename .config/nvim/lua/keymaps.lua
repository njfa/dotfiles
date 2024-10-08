local map = require('common').map
-- local buf_map = require('common').buf_map

if vim.fn.exists("g:vscode") ~= 0 then
    -- 移動
    map("n", "gj",
        "<cmd>call VSCodeNotify('cursorMove', { 'to': 'down', 'by': 'wrappedLine', 'value': v:count ? v:count : 1 })<cr>")
    map("n", "gk",
        "<cmd>call VSCodeNotify('cursorMove', { 'to': 'up', 'by': 'wrappedLine', 'value': v:count ? v:count : 1 })<cr>")
    map("n", "gn", "<cmd>call VSCodeNotify('editor.action.marker.next')<cr>")
    map("n", "gp", "<cmd>call VSCodeNotify('editor.action.marker.prev')<cr>")

    map("n", "gh", "<cmd>call VSCodeNotify('editor.action.goToReferences')<cr>")
    map("n", "gi", "<cmd>call VSCodeNotify('editor.action.peekImplementation')<cr>")
    map("n", "gd", "<cmd>call VSCodeNotify('editor.action.peekDefinition')<cr>")
    map("n", "gs", "<cmd>call VSCodeNotify('editor.action.peekTypeDefinition')<cr>")
    map("n", "gr", "<cmd>call VSCodeNotify('editor.action.rename')<cr>")

    -- インデント
    map("n", "<", "<cmd>call VSCodeNotify('editor.action.outdentLines')<cr>")
    map("n", ">", "<cmd>call VSCodeNotify('editor.action.indentLines')<cr>")
    map("x", "<", "<cmd>call VSCodeNotifyVisual('editor.action.outdentLines', 1)<cr>")
    map("x", ">", "<cmd>call VSCodeNotifyVisual('editor.action.indentLines', 1)<cr>")

    -- ファイル操作
    map("n", "<leader>f", "<cmd>call VSCodeNotify('workbench.action.quickOpen')<cr>")
    map("n", "<leader>w", "<cmd>call VSCodeNotify('workbench.action.files.save')<cr>")
    map("n", "<leader>q", "<cmd>call VSCodeNotify('workbench.action.closeActiveEditor')<cr>")
    map("n", "<leader>r", "<cmd>call VSCodeNotify('workbench.action.openRecent')<cr>")
    map("n", "<leader>u", "<cmd>call VSCodeNotify('timeline.focus')<cr>")
    map("n", "<leader>c", "<cmd>call VSCodeNotify('workbench.action.files.newUntitledFile')<cr>")
    map("n", "<C-h>", "<cmd>Tabprevious<cr>")
    map("n", "<C-l>", "<cmd>Tabnext<cr>")

    map("n", "u", "<cmd>call VSCodeNotify('undo')<cr>")
    map("n", "<C-r>", "<cmd>call VSCodeNotify('redo')<cr>")

    map("n", "<leader>:", "<cmd>call VSCodeNotify('workbench.action.showCommands')<cr>")
    map("n", "<leader>/", "<cmd>call VSCodeNotify('workbench.action.findInFiles')<cr>")

    -- ウィンドウ操作
    map("n", "<C-w>e", "<cmd>call VSCodeNotify('workbench.action.splitEditor')<cr>")
    map("n", "<C-w>i", "<cmd>call VSCodeNotify('workbench.action.splitEditorOrthogonal')<cr>")
    map("n", "<C-w>=", "<cmd>call VSCodeNotify('workbench.action.evenEditorWidths')<cr>")
    map("n", "<C-w>.", "<cmd>call VSCodeNotify('workbench.action.increaseViewSize')<cr>")
    map("n", "<C-w>,", "<cmd>call VSCodeNotify('workbench.action.decreaseViewSize')<cr>")
    map("n", "<C-w>r", "<cmd>call VSCodeNotify('workbench.action.reloadWindow')<cr>")
    map("n", "<C-w>a", "<cmd>call VSCodeNotify('workbench.action.toggleActivityBarVisibility')<cr>")
    map("n", "<C-w>b", "<cmd>call VSCodeNotify('workbench.action.toggleSidebarVisibility')<cr>")

    -- サイドバー操作
    map("n", "<leader>s", "<cmd>call VSCodeNotify('workbench.action.focusSideBar')<cr>")

    -- パネル操作
    map("n", "<C-w>p",
        "<cmd>call VSCodeNotify('workbench.action.togglePanel')<cr>:sleep 100m<cr><cmd>call VSCodeNotify('workbench.action.focusActiveEditorGroup')<cr>")
end
