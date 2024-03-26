local map = require('common').map
local buf_map = require('common').buf_map

-- 行頭への移動を先頭の文字に変更
map("n", "0", "^")
map("n", "^", "0")

-- 現在の行を上下に移動
map("n", "<C-Up>", '"zdd<Up>"zP')
map("n", "<C-Down>", '"zdd"zp')

-- 複数行を移動
map("v", "<C-Up>", '"zx<Up>"zP`[V`]')
map("v", "<C-Down>", '"zx"zp`[V`]')

-- " 検索
-- nnoremap <expr> <leader>r ':<c-u>%s/' . expand('<cword>') . '/'
-- nnoremap <expr> <leader>s ':<c-u>%s/'
map("n", "<leader>s", [[:<c-u>%s/]])
map("x", "<leader>s", [[:<c-u>'<,'>s/]])
map("n", "<leader>S", [[:<c-u>%s/\v]])
map("x", "<leader>S", [[:<c-u>'<,'>s/\v]])

-- " レジスタに入れずに文字削除
map("n", "s", '"_s')
map("n", "x", '"_x')
map("v", "s", '"_s')
map("v", "x", '"_x')

-- " 選択箇所をレジスタに入れずにペースト
map("x", "p", 'pgvy')
map("x", "P", 'Pgvy')

-- テキストオブジェクトの操作
map("n", "ys", [[<Plug>(operator-sandwich-add)]])
map("n", "ds", [[<Plug>(operator-sandwich-delete)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-query-a)]])
map("n", "cs", [[<Plug>(operator-sandwich-replace)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-query-a)]])

-- インデント時の選択範囲を維持
map("x", ">", ">gv")
map("x", "<", "<gv")

-- C-a、C-x時の選択範囲を維持
map("x", "<C-a>", "<C-a>gv")
map("x", "<C-x>", "<C-x>gv")

if vim.fn.exists("g:vscode") == 0 then
    -- Telescope
    -- 隠しファイルも検索対象に含めるためにrgを利用する
    -- which-keyで定義済みのためコメントアウト
    -- map("n", "<leader>f", "<Cmd>lua require('picker').find_files_from_project_git_root()<CR>")
    -- map("n", "<leader>F", ":lua require('picker').find_files_from_project_git_root( { search_file=\"\" })<left><left><left><left>")
    -- map("x", "<leader>f", "<Cmd>lua require('picker').find_files_string_visual()<CR>")
    -- map("n", "<leader>g", "<Cmd>lua require('picker').live_grep_from_project_git_root()<CR>")
    -- map("n", "<leader>G", ":lua require('picker').live_grep_from_project_git_root( { glob_pattern=\"\" })<left><left><left><left>")
    -- map("x", "<leader>g", "<Cmd>lua require('picker').grep_string_visual()<CR>")
    -- map("n", "<leader>h", "<Cmd>lua require('telescope').extensions.frecency.frecency()<CR>")
    -- map("n", "<leader>H", "<Cmd>lua require('picker').find_files_from_project_git_root({oldfiles=true})<CR>")

    map("n", "<A-s>", "<cmd>Fern . -reveal=% -drawer -toggle<cr>")
    -- map("n", "<leader>r", "<Cmd>lua require('telescope').extensions.frecency.frecency()<CR>")
    -- map("n", "<leader>rr", "[[<Plug>RestNvim]]")
    -- map("n", "<leader>rp", "[[<Plug>RestNvimPreview]]")
    -- map("n", "<leader>r.", "[[<Plug>RestNvimLast]]")
    -- map("n", "<learer>re", ":RestSelectEnv ")
    map("n", "<leader>b", "<Cmd>BufferLinePick<CR>")
    map("n", "<leader>B", "<Cmd>Telescope buffers<CR>")
    map("n", "<leader>i", "<Cmd>lua require('telescope.builtin').diagnostics({ bufnr=0 })<CR>")
    -- map("n", "<leader>I", "<Cmd>lua require('telescope.builtin').diagnostics({})<CR>")
    map("n", "<leader>p", "<Cmd>Telescope registers<CR>")
    -- map("n", "<leader>p", "<Cmd>Trouble<CR>")
    map("n", "<leader>T", "<Cmd>TodoTelescope<CR>")
    map("n", "<leader>:", "<Cmd>lua require('picker').command_history()<CR>")
    -- map("n", "<leader>:", "<Cmd>Telescope command_history<CR>")
    map("n", "<leader>/", "<Cmd>Telescope current_buffer_fuzzy_find<CR>")
    map("n", "<leader>e", "<Cmd>Telescope projects<CR>")
    -- map("n", "<leader>s", "<cmd>SidebarNvimToggle<cr>")

    map("n", "<leader>xx", function() require("trouble").toggle() end)
    map("n", "<leader>xw", function() require("trouble").toggle("workspace_diagnostics") end)
    map("n", "<leader>xd", function() require("trouble").toggle("document_diagnostics") end)
    map("n", "<leader>xr", function() require("trouble").toggle("lsp_references") end)
    map("n", "<leader>xt", function() require("trouble").toggle("lsp_type_definitions") end)
    map("n", "<leader>xD", function() require("trouble").toggle("lsp_definitions") end)

    -- タブ、バッファ操作
    map("n", "<leader>w", "<cmd>w<cr>", { silent = true })
    map("n", "<leader>q", "<cmd>q<cr>", { silent = true })
    map("n", "<leader>Q", "<cmd>qa!<cr>", { silent = true })
    -- 単にbdeleteを実行すると、タブ中の空バッファを閉じたときにタブも一緒に閉じられてしまう
    map("n", "<leader>d", "<cmd>bp<bar>sp<bar>bn<bar>bd!<cr>", { silent = true })
    map("n", "<leader>D", "<Cmd>tabclose<CR>", { silent = true })
    map("n", "<leader>c", '<cmd>enew<cr>', { silent = true })
    map("n", "<leader>C", '<cmd>tabnew<cr>', { silent = true })
    map("n", "<C-p>", '<cmd>tabp<cr>', { silent = true })
    map("n", "<C-n>", '<cmd>tabn<cr>', { silent = true })
    -- map("n", "<C-h>", "<cmd>bp<cr>", { silent = true })
    -- map("n", "<C-l>", "<cmd>bn<cr>", { silent = true })
    map("n", "<C-h>", "<cmd>BufferLineCyclePrev<cr>", { silent = true })
    map("n", "<C-l>", "<cmd>BufferLineCycleNext<cr>", { silent = true })

    -- undotree
    map("n", "<leader>u", "<cmd>UndotreeToggle<cr>")

    -- 改行
    -- map("n", "<cr>", "o<Esc>0D")
    map("n", "<C-j>", 'o<Esc>0"_D')
    map("n", "<C-k>", 'O<Esc>0"_D')

    -- ウィンドウ操作
    map("n", "<C-w>e", "<cmd>vsplit<cr>")
    map("n", "<C-w>i", "<cmd>split<cr>")

    -- ローカルのディレクトリを変更
    map("n", "<C-w>.", function() require('common').lcd_current_workspace() end, { silent = true })

    map("n", "<leader>.", "<cmd>lua require('reload').reload()<cr>")

    map("n", "<A-p>", "<cmd>MarkdownPreview<cr>")
    map("n", "<C-w>d", "<cmd>DiffviewFileHistory<cr>")

    -- Align
    map("n", "ga", "<Plug>(EasyAlign)")
    map("x", "ga", "<Plug>(EasyAlign)")

    -- 表編集
    map("n", "<leader>t", "<Cmd>TableModeToggle<CR>")
    map("x", "<Bar>", ":EasyAlign*<Bar><CR>")

    -- Switch
    map("n", "ms", "<cmd>Switch<cr>")
    map("x", "ms", "<cmd>Switch<cr>")

    -- 検索
    map('n', '*', [[<Plug>(asterisk-z*)<Cmd>lua require('hlslens').start()<CR>]])
    map('n', '#', [[<Plug>(asterisk-z#)<Cmd>lua require('hlslens').start()<CR>]])
    map('n', 'g*', [[<Plug>(asterisk-gz*)<Cmd>lua require('hlslens').start()<CR>]])
    map('n', 'g#', [[<Plug>(asterisk-gz#)<Cmd>lua require('hlslens').start()<CR>]])

    map('x', '*', [[<Plug>(asterisk-z*)<Cmd>lua require('hlslens').start()<CR>]])
    map('x', '#', [[<Plug>(asterisk-z#)<Cmd>lua require('hlslens').start()<CR>]])
    map('x', 'g*', [[<Plug>(asterisk-gz*)<Cmd>lua require('hlslens').start()<CR>]])
    map('x', 'g#', [[<Plug>(asterisk-gz#)<Cmd>lua require('hlslens').start()<CR>]])

    -- Escで検索結果のハイライトを削除
    map("n", "<Esc>", ':noh<cr>', { silent = true })

    -- 移動
    local hop = require('hop')
    local directions = require('hop.hint').HintDirection
    map('n', 'L', function() hop.hint_lines_skip_whitespace({ direction = directions.AFTER_CURSOR }) end, {})
    map('n', 'H', function() hop.hint_lines_skip_whitespace({ direction = directions.BEFORE_CURSOR }) end, {})
    map('n', 'w', function() hop.hint_words({ direction = directions.AFTER_CURSOR, current_line_only = false }) end, {})
    map('n', 'b', function() hop.hint_words({ direction = directions.BEFORE_CURSOR, current_line_only = false }) end, {})
    map('n', 'W', function() hop.hint_words({ direction = directions.AFTER_CURSOR, current_line_only = true }) end, {})
    map('n', 'B', function() hop.hint_words({ direction = directions.BEFORE_CURSOR, current_line_only = true }) end, {})
    map('x', 'w', function() hop.hint_words({ direction = directions.AFTER_CURSOR, current_line_only = false }) end, {})
    map('x', 'b', function() hop.hint_words({ direction = directions.BEFORE_CURSOR, current_line_only = false }) end, {})
    map('x', 'W', function() hop.hint_words({ direction = directions.AFTER_CURSOR, current_line_only = true }) end, {})
    map('x', 'B', function() hop.hint_words({ direction = directions.BEFORE_CURSOR, current_line_only = true }) end, {})
    map('n', 'f', function() hop.hint_char1({ current_line_only = false }) end, {})
    map('n', 'F', function() hop.hint_char1({ current_line_only = false }) end, {})
    map('n', 't', function() hop.hint_char1({ current_line_only = false, hint_offset = -1 }) end, {})
    map('n', 'T', function() hop.hint_char1({ current_line_only = false, hint_offset = 1 }) end, {})
    map('x', 'f', function() hop.hint_char1({ current_line_only = false }) end, {})
    map('x', 'F', function() hop.hint_char1({ current_line_only = false }) end, {})
    map('x', 't', function() hop.hint_char1({ current_line_only = false, hint_offset = -1 }) end, {})
    map('x', 'T', function() hop.hint_char1({ current_line_only = false, hint_offset = 1 }) end, {})

    map("n", "R", "<cmd>lua require'substitute'.operator()<cr>", {})
    map('x', 'm', ":lua require('tsht').nodes()<cr>", {})

    -- 編集
    map("n", "R", "<cmd>lua require'substitute'.operator()<cr>", {})
    map("x", "R", "<cmd>lua require'substitute'.visual()<cr>", {})

    -- fern
    vim.api.nvim_create_autocmd({"FileType"}, {
        pattern = {"fern"},
        callback = function()
            vim.cmd("setlocal nonumber")
            buf_map(0, 'n', 'r', [[<Plug>(fern-action-rename)]], {})
            buf_map(0, 'n', 'R', [[<Plug>(fern-action-remove)]], {})

            -- Fern上のディレクトリ移動時にルートディレクトリを変更する
            buf_map(0, 'n', [[<Plug>(fern-my-enter-and-tcd)]], [[<Plug>(fern-action-open-or-enter)<Plug>(fern-wait)<Plug>(fern-action-tcd:root)]], {})
            buf_map(0, 'n', [[<Plug>(fern-my-leave-and-tcd)]], [[<Plug>(fern-action-leave)<Plug>(fern-wait)<Plug>(fern-action-tcd:root)]], {})
            buf_map(0, 'n', '<CR>', [[<Plug>(fern-my-enter-and-tcd)]], {})
            buf_map(0, 'n', '<BS>', [[<Plug>(fern-my-leave-and-tcd)]], {})
            buf_map(0, 'n', '<C-H>', [[<Plug>(fern-my-leave-and-tcd)]], {})

            -- プレビューする
            -- buf_map(0, 'n', [[<Plug>(fern-my-preview-or-nop)]], [[fern#smart#leaf("<Plug>(fern-action-open:edit)<C-w>p", "")]], { expr = true })
            -- buf_map(0, 'n', 'j', [[fern#smart#drawer("j<Plug>(fern-my-preview-or-nop)", "j")]], { expr = true })
            -- buf_map(0, 'n', 'k', [[fern#smart#drawer("k<Plug>(fern-my-preview-or-nop)", "k")]], { expr = true })
            buf_map(0, 'n', [[<Plug>(fern-quit-or-close-preview)]], [[fern_preview#smart_preview("<Plug>(fern-action-preview:close)", ":q<CR>")]], { expr = true })
            buf_map(0, 'n', 'q', [[<Plug>(fern-quit-or-close-preview)]], {})
            buf_map(0, 'n', '<Esc>', [[<Plug>(fern-quit-or-close-preview)]], {})
            buf_map(0, 'n', 'p', [[<Plug>(fern-action-preview:auto:toggle)]], {})

            buf_map(0, 'n', [[<Plug>(fern-preview-down-or-page-down)]], [[fern_preview#smart_preview("<Plug>(fern-action-preview:scroll:down:half)", "<C-d>")]], { expr = true })
            buf_map(0, 'n', [[<Plug>(fern-preview-up-or-page-up)]], [[fern_preview#smart_preview("<Plug>(fern-action-preview:scroll:up:half)", "<C-u>")]], { expr = true })
            buf_map(0, 'n', '<C-d>', [[<Plug>(fern-preview-down-or-page-down)]], {})
            buf_map(0, 'n', '<C-u>', [[<Plug>(fern-preview-up-or-page-up)]], {})

            buf_map(0, "n", "<C-j>", '<cmd>tabp<cr>', {})
            buf_map(0, "n", "<C-k>", '<cmd>tabn<cr>', {})
        end,
    })

    -- Debugger
    map('n', '<F1>', "<cmd>lua require'telescope'.extensions.dap.configurations{}<CR>", {})
    map('n', '<F2>', "<cmd>lua require('telescope').extensions.dap.commands{}<CR>", {})
    map('n', '<F3>', "<cmd>lua require'telescope'.extensions.dap.list_breakpoints{}<CR>", {})
    map('n', '<F4>', "<cmd>lua require('dap').set_breakpoint()<CR>", {})
    map('n', '<F5>', "<cmd>lua require('dap').toggle_breakpoint()<CR>", {})

    map('n', '<F6>', "<cmd>lua require('dap').step_into()<CR>", {})
    map('n', '<F7>', "<cmd>lua require('dap').continue()<CR>", {})
    map('n', '<F8>', "<cmd>lua require('dap').step_over()<CR>", {})
    map('n', '<F9>', "<cmd>lua require('dap').step_out()<CR>", {})

    map('n', '<F12>', "<cmd>lua require('dapui').toggle()<CR>", {})
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
