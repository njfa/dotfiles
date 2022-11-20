-- Functional wrapper for mapping custom keybindings
function map(mode, lhs, rhs, opts)
    local options = { noremap = true }
    if opts then
        options = vim.tbl_extend("force", options, opts)
    end
    vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

function buf_map(num, mode, lhs, rhs, opts)
    local options = { noremap = true, silent = true }
    if opts then
        options = vim.tbl_extend("force", options, opts)
    end
    vim.api.nvim_buf_set_keymap(num, mode, lhs, rhs, options)
end

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
map("n", "<Esc>", ':noh<cr>')
-- nnoremap <expr> <leader>r ':<c-u>%s/' . expand('<cword>') . '/'
-- nnoremap <expr> <leader>s ':<c-u>%s/'
-- vnoremap <expr> <leader>s ":<c-u>'<,'>s/"
-- nnoremap <expr> <leader>S ':<c-u>%s/\v'
-- vnoremap <expr> <leader>S ":<c-u>'<,'>s/\\v"

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
    map("n", "<leader>f", "<Cmd>Telescope find_files find_command=rg,--ignore,--hidden,--files<CR>")
    map("n", "<leader>s", "<cmd>Fern . -reveal=% -drawer -toggle<cr>")
    map("n", "<A-s>", "<cmd>Fern . -reveal=% -drawer -toggle<cr>")
    map("n", "<leader>r", "<Cmd>lua require('telescope').extensions.frecency.frecency()<CR>")
    map("n", "<leader>b", "<Cmd>Telescope buffers<CR>")
    -- map("n", "<leader>p", "<Cmd>Telescope registers<CR>")
    map("n", "<leader>p", "<Cmd>Trouble<CR>")
    map("n", "<leader>t", "<Cmd>TodoTelescope<CR>")
    map("n", "<leader>g", "<Cmd>Telescope live_grep<CR>")
    map("n", "<leader>:", "<Cmd>Telescope command_history<CR>")
    map("n", "<leader>/", "<Cmd>Telescope current_buffer_fuzzy_find<CR>")
    -- map("n", "<leader>s", "<cmd>SidebarNvimToggle<cr>")

    -- タブ、バッファ操作
    map("n", "<leader>w", "<cmd>w<cr>", { silent = true })
    map("n", "<leader>q", "<cmd>q<cr>", { silent = true })
    map("n", "<leader>Q", "<cmd>qa<cr>", { silent = true })
    -- 単にbdeleteを実行すると、タブ中の空バッファを閉じたときにタブも一緒に閉じられてしまう
    map("n", "<leader>d", "<cmd>bp<bar>sp<bar>bn<bar>bd<cr>", { silent = true })
    map("n", "<leader>D", "<Cmd>tabclose<CR>", { silent = true })
    map("n", "<leader>c", '<cmd>enew<cr>', { silent = true })
    map("n", "<leader>C", '<cmd>tabnew<cr>', { silent = true })
    map("n", "<C-j>", '<cmd>tabp<cr>', { silent = true })
    map("n", "<C-k>", '<cmd>tabn<cr>', { silent = true })
    map("n", "<C-h>", "<cmd>bp<cr>", { silent = true })
    map("n", "<C-l>", "<cmd>bn<cr>", { silent = true })

    -- undotree
    map("n", "<leader>u", "<cmd>UndotreeToggle<cr>")

    -- 改行
    map("n", "<cr>", "o<Esc>")
    map("n", "<leader><cr>", "O<Esc>")

    -- ウィンドウ操作
    map("n", "<C-w>e", "<cmd>vsplit<cr>")
    map("n", "<C-w>i", "<cmd>split<cr>")
    map("n", "<C-w>.", "<cmd>lcd %:h<cr>")

    -- Align
    map("n", "ga", "<Plug>(EasyAlign)")
    map("x", "ga", "<Plug>(EasyAlign)")

    -- Switch
    map("n", "gs", "<cmd>Switch<cr>")
    map("x", "gs", "<cmd>Switch<cr>")

    -- 検索
    map('n', '*', [[<Plug>(asterisk-z*)<Cmd>lua require('hlslens').start()<CR>]])
    map('n', '#', [[<Plug>(asterisk-z#)<Cmd>lua require('hlslens').start()<CR>]])
    map('n', 'g*', [[<Plug>(asterisk-gz*)<Cmd>lua require('hlslens').start()<CR>]])
    map('n', 'g#', [[<Plug>(asterisk-gz#)<Cmd>lua require('hlslens').start()<CR>]])

    map('x', '*', [[<Plug>(asterisk-z*)<Cmd>lua require('hlslens').start()<CR>]])
    map('x', '#', [[<Plug>(asterisk-z#)<Cmd>lua require('hlslens').start()<CR>]])
    map('x', 'g*', [[<Plug>(asterisk-gz*)<Cmd>lua require('hlslens').start()<CR>]])
    map('x', 'g#', [[<Plug>(asterisk-gz#)<Cmd>lua require('hlslens').start()<CR>]])

    -- 移動
    map('n', 'f', "<cmd>lua require'hop'.hint_char1({ direction = require'hop.hint'.HintDirection.AFTER_CURSOR, current_line_only = false })<cr>", {})
    map('n', 'F', "<cmd>lua require'hop'.hint_char1({ direction = require'hop.hint'.HintDirection.BEFORE_CURSOR, current_line_only = false })<cr>", {})
    map('n', 't', "<cmd>lua require'hop'.hint_char1({ direction = require'hop.hint'.HintDirection.AFTER_CURSOR, current_line_only = false, hint_offset = -1 })<cr>", {})
    map('n', 'T', "<cmd>lua require'hop'.hint_char1({ direction = require'hop.hint'.HintDirection.BEFORE_CURSOR, current_line_only = false, hint_offset = 1 })<cr>", {})
    map('x', 'f', "<cmd>lua require'hop'.hint_char1({ direction = require'hop.hint'.HintDirection.AFTER_CURSOR, current_line_only = false })<cr>", {})
    map('x', 'F', "<cmd>lua require'hop'.hint_char1({ direction = require'hop.hint'.HintDirection.BEFORE_CURSOR, current_line_only = false })<cr>", {})
    map('x', 't', "<cmd>lua require'hop'.hint_char1({ direction = require'hop.hint'.HintDirection.AFTER_CURSOR, current_line_only = false, hint_offset = -1 })<cr>", {})
    map('x', 'T', "<cmd>lua require'hop'.hint_char1({ direction = require'hop.hint'.HintDirection.BEFORE_CURSOR, current_line_only = false, hint_offset = 1 })<cr>", {})
    map('n', 'gw', "<cmd>HopWord<cr>", {})
    map('x', 'gw', "<cmd>HopWord<cr>", {})
    map('n', 'gl', "<cmd>HopLineStart<cr>", {})
    map('x', 'gl', "<cmd>HopLineStart<cr>", {})
    map('n', 'g/', "<cmd>HopPattern<cr>", {})
    map('x', 'g/', "<cmd>HopPattern<cr>", {})
    map('o', 'm', "<cmd>lua require('tsht').nodes()<cr>", {})
    map('x', 'm', ":lua require('tsht').nodes()<cr>", {})

    -- 編集
    map("n", "R", "<cmd>lua require'substitute'.operator()<cr>", { noremap = true })
    map("x", "R", "<cmd>lua require'substitute'.visual()<cr>", { noremap = true })

    -- fern
    vim.api.nvim_create_autocmd({"FileType"}, {
        pattern = {"fern"},
        callback = function()
            -- Fern上のディレクトリ移動時にルートディレクトリを変更する
            buf_map(0, 'n', [[<Plug>(fern-my-enter-and-tcd)]], [[<Plug>(fern-action-open-or-enter)<Plug>(fern-wait)<Plug>(fern-action-tcd:root)]], { noremap = true })
            buf_map(0, 'n', [[<Plug>(fern-my-leave-and-tcd)]], [[<Plug>(fern-action-leave)<Plug>(fern-wait)<Plug>(fern-action-tcd:root)]], { noremap = true })
            buf_map(0, 'n', '<CR>', [[<Plug>(fern-my-enter-and-tcd)]], { noremap = true })
            buf_map(0, 'n', '<BS>', [[<Plug>(fern-my-leave-and-tcd)]], { noremap = true })
            buf_map(0, 'n', '<C-H>', [[<Plug>(fern-my-leave-and-tcd)]], { noremap = true })

            -- プレビューする
            -- buf_map(0, 'n', [[<Plug>(fern-my-preview-or-nop)]], [[fern#smart#leaf("<Plug>(fern-action-open:edit)<C-w>p", "")]], { noremap = true, expr = true })
            -- buf_map(0, 'n', 'j', [[fern#smart#drawer("j<Plug>(fern-my-preview-or-nop)", "j")]], { noremap = true, expr = true })
            -- buf_map(0, 'n', 'k', [[fern#smart#drawer("k<Plug>(fern-my-preview-or-nop)", "k")]], { noremap = true, expr = true })
            buf_map(0, 'n', [[<Plug>(fern-quit-or-close-preview)]], [[fern_preview#smart_preview("<Plug>(fern-action-preview:close)", ":q<CR>")]], { noremap = true, expr = true })
            buf_map(0, 'n', 'q', [[<Plug>(fern-quit-or-close-preview)]], { noremap = true })
            buf_map(0, 'n', '<Esc>', [[<Plug>(fern-quit-or-close-preview)]], { noremap = true })
            buf_map(0, 'n', 'p', [[<Plug>(fern-action-preview:auto:toggle)]], { noremap = true, silent = true })

            buf_map(0, 'n', [[<Plug>(fern-preview-down-or-page-down)]], [[fern_preview#smart_preview("<Plug>(fern-action-preview:scroll:down:half)", "<C-d>")]], { noremap = true, expr = true })
            buf_map(0, 'n', [[<Plug>(fern-preview-up-or-page-up)]], [[fern_preview#smart_preview("<Plug>(fern-action-preview:scroll:up:half)", "<C-u>")]], { noremap = true, expr = true })
            buf_map(0, 'n', '<C-d>', [[<Plug>(fern-preview-down-or-page-down)]], { noremap = true, silent = true })
            buf_map(0, 'n', '<C-u>', [[<Plug>(fern-preview-up-or-page-up)]], { noremap = true, silent = true })
        end,
    })

    -- lspsaga
    my_lsp_on_attach = function(client, bufnr)
        buf_map(bufnr, "n", "gh", "<cmd>lua require('lspsaga.provider').lsp_finder()<CR>", {silent = true, noremap = true})
        buf_map(bufnr, "n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", {silent = true, noremap = true})
        buf_map(bufnr, "n", "gs", "<cmd>lua require('lspsaga.signaturehelp').signature_help()<CR>", {silent = true, noremap = true})
        buf_map(bufnr, "n", "gr", "<cmd>lua require('lspsaga.rename').rename()<CR>", {silent = true, noremap = true})
        buf_map(bufnr, "n", "gx", "<cmd>lua require('lspsaga.codeaction').code_action()<CR>", {silent = true, noremap = true})
        buf_map(bufnr, "x", "gx", "<cmd>Lspsaga range_code_action<cr>", {silent = true, noremap = true})
        buf_map(bufnr, "n", "K", "<cmd>Lspsaga hover_doc<cr>", {silent = true, noremap = true})
        buf_map(bufnr, "n", "go", "<cmd>Lspsaga show_line_diagnostics<cr>", {silent = true, noremap = true})
        buf_map(bufnr, "n", "gn", "<cmd>Lspsaga diagnostic_jump_next<cr>", {silent = true, noremap = true})
        buf_map(bufnr, "n", "gp", "<cmd>Lspsaga diagnostic_jump_prev<cr>", {silent = true, noremap = true})
        buf_map(bufnr, "n", "gd", "<cmd>lua require('lspsaga.provider').preview_definition()<CR>", {silent = true, noremap = true})
        buf_map(bufnr, "n", "<C-u>", "<cmd>lua require('lspsaga.action').smart_scroll_with_saga(-1, '<c-u>')<cr>", {})
        buf_map(bufnr, "n", "<C-d>", "<cmd>lua require('lspsaga.action').smart_scroll_with_saga(1, '<c-d>')<cr>", {})

        -- require("aerial").on_attach(client, bufnr)
        require("nvim-navic").attach(client, bufnr)
    end

    my_aerial_on_attach = function(bufnr)
        -- Toggle the aerial window with <leader>a
        buf_map(bufnr, 'n', '<leader>a', '<cmd>AerialToggle!<CR>', {})
        -- Jump forwards/backwards with '{' and '}'
        buf_map(bufnr, 'n', '}', '<cmd>AerialPrev<CR>', {})
        buf_map(bufnr, 'n', '{', '<cmd>AerialNext<CR>', {})
        -- Jump up the tree with '[[' or ']]'
        buf_map(bufnr, 'n', ']]', '<cmd>lua require("aerial").prev_up()<CR>', {})
        buf_map(bufnr, 'n', '[[', '<cmd>lua require("aerial").next_up()<CR>', {})
    end
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
