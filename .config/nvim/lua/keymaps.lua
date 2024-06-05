local map = require('common').map
local buf_map = require('common').buf_map

if vim.fn.exists("g:vscode") == 0 then

    -- fern
    vim.api.nvim_create_autocmd({"FileType"}, {
        pattern = {"fern"},
        callback = function()
            vim.cmd("setlocal nonumber")

            local wk = require("which-key")
            wk.register({
                ['r'] = { [[<Plug>(fern-action-rename)]], "リネーム" },
                ['R'] = { [[<Plug>(fern-action-remove)]], "削除" },
                ['<CR>'] = { [[<Plug>(fern-my-enter-and-tcd)]], "選択したディレクトリに移動" },
                ['<BS>'] = { [[<Plug>(fern-my-leave-and-tcd)]], "1階層上に移動" },
                ['<C-H>'] = { [[<Plug>(fern-my-leave-and-tcd)]], "1階層上に移動" },
                ['q'] = { [[<Plug>(fern-quit-or-close-preview)]], "閉じる / プレビューを停止" },
                ['<Esc>'] = { [[<Plug>(fern-quit-or-close-preview)]], "閉じる / プレビューを停止" },
                ['p'] = { [[<Plug>(fern-action-preview:auto:toggle)]], "プレビューの表示/非表示切替" },
                ['<C-d>'] = { [[<Plug>(fern-preview-down-or-page-down)]], "プレビューをスクロール (下)" },
                ['<C-u>'] = { [[<Plug>(fern-preview-up-or-page-up)]], "プレビューをスクロール (上)" },
                ["<C-j>"] = { '<cmd>tabp<cr>', "前のタブに移動" },
                ["<C-k>"] = { '<cmd>tabn<cr>', "次のタブに移動" },
            }, {
                mode = "n",
                buffer = 0
            })
            -- buf_map(0, 'n', 'r', [[<Plug>(fern-action-rename)]], {})
            -- buf_map(0, 'n', 'R', [[<Plug>(fern-action-remove)]], {})

            -- -- Fern上のディレクトリ移動時にルートディレクトリを変更する
            buf_map(0, 'n', [[<Plug>(fern-my-enter-and-tcd)]], [[<Plug>(fern-action-open-or-enter)<Plug>(fern-wait)<Plug>(fern-action-tcd:root)]], {})
            buf_map(0, 'n', [[<Plug>(fern-my-leave-and-tcd)]], [[<Plug>(fern-action-leave)<Plug>(fern-wait)<Plug>(fern-action-tcd:root)]], {})
            -- buf_map(0, 'n', '<CR>', [[<Plug>(fern-my-enter-and-tcd)]], {})
            -- buf_map(0, 'n', '<BS>', [[<Plug>(fern-my-leave-and-tcd)]], {})
            -- buf_map(0, 'n', '<C-H>', [[<Plug>(fern-my-leave-and-tcd)]], {})

            -- -- プレビューする
            buf_map(0, 'n', [[<Plug>(fern-my-preview-or-nop)]], [[fern#smart#leaf("<Plug>(fern-action-open:edit)<C-w>p", "")]], { expr = true })
            -- -- buf_map(0, 'n', 'j', [[fern#smart#drawer("j<Plug>(fern-my-preview-or-nop)", "j")]], { expr = true })
            -- -- buf_map(0, 'n', 'k', [[fern#smart#drawer("k<Plug>(fern-my-preview-or-nop)", "k")]], { expr = true })
            buf_map(0, 'n', [[<Plug>(fern-quit-or-close-preview)]], [[fern_preview#smart_preview("<Plug>(fern-action-preview:close)", ":q<CR>")]], { expr = true })
            -- buf_map(0, 'n', 'q', [[<Plug>(fern-quit-or-close-preview)]], {})
            -- buf_map(0, 'n', '<Esc>', [[<Plug>(fern-quit-or-close-preview)]], {})
            -- buf_map(0, 'n', 'p', [[<Plug>(fern-action-preview:auto:toggle)]], {})

            buf_map(0, 'n', [[<Plug>(fern-preview-down-or-page-down)]], [[fern_preview#smart_preview("<Plug>(fern-action-preview:scroll:down:half)", "<C-d>")]], { expr = true })
            buf_map(0, 'n', [[<Plug>(fern-preview-up-or-page-up)]], [[fern_preview#smart_preview("<Plug>(fern-action-preview:scroll:up:half)", "<C-u>")]], { expr = true })
            -- buf_map(0, 'n', '<C-d>', [[<Plug>(fern-preview-down-or-page-down)]], {})
            -- buf_map(0, 'n', '<C-u>', [[<Plug>(fern-preview-up-or-page-up)]], {})

            -- buf_map(0, "n", "<C-j>", '<cmd>tabp<cr>', {})
            -- buf_map(0, "n", "<C-k>", '<cmd>tabn<cr>', {})
        end,
    })
else
    -- 移動
    map("n", "gj", "<cmd>call VSCodeNotify('cursorMove', { 'to': 'down', 'by': 'wrappedLine', 'value': v:count ? v:count : 1 })<cr>")
    map("n", "gk", "<cmd>call VSCodeNotify('cursorMove', { 'to': 'up', 'by': 'wrappedLine', 'value': v:count ? v:count : 1 })<cr>")
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
    map("n", "<C-w>e","<cmd>call VSCodeNotify('workbench.action.splitEditor')<cr>")
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
    map("n", "<C-w>p", "<cmd>call VSCodeNotify('workbench.action.togglePanel')<cr>:sleep 100m<cr><cmd>call VSCodeNotify('workbench.action.focusActiveEditorGroup')<cr>")

end
