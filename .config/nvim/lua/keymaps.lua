-- Functional wrapper for mapping custom keybindings
function map(mode, lhs, rhs, opts)
    local options = { noremap = true }
    if opts then
        options = vim.tbl_extend("force", options, opts)
    end
    vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

function buf_map(num, mode, lhs, rhs, opts)
    local options = { noremap = true }
    if opts then
        options = vim.tbl_extend("force", options, opts)
    end
    vim.api.nvim_buf_set_keymap(num, mode, lhs, rhs, options)
end

-- 行頭への移動を先頭の文字に変更
map("n", "0", "^")
map("n", "^", "0")

-- 現在の行を上下に移動
map("n", "<C-Up>", '"zdd<Up>"zP', {silent = true})
map("n", "<C-Down>", '"zdd"zp', {silent = true})

-- 複数行を移動
map("v", "<C-Up>", '"zx<Up>"zP`[V`]', {silent = true})
map("v", "<C-Down>", '"zx"zp`[V`]', {silent = true})

-- " 検索
map("n", "<Esc>", ':noh<cr>', {silent = true})
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

if vim.fn.exists("g:vscode") == 0 then
    -- Telescope
    if vim.fn.executable('fd') == 1 then
        map("n", "<leader>f", "<cmd>Telescope fd<cr>", {silent = true})
    else
        map("n", "<leader>f", "<cmd>Telescope find_files<cr>", {silent = true})
    end
    map("n", "<leader>e", "<cmd>Fern . -reveal=% -drawer -toggle<cr>", {silent = true})
    map("n", "<leader>r", "<Cmd>lua require('telescope').extensions.frecency.frecency()<CR>", {silent = true})
    map("n", "<leader>b", "<Cmd>Telescope buffers<CR>", {silent = true})
    -- map("n", "<leader>p", "<Cmd>Telescope registers<CR>", {silent = true})
    map("n", "<leader>p", "<Cmd>Trouble<CR>", {silent = true})
    map("n", "<leader>g", "<Cmd>Telescope live_grep<CR>", {silent = true})
    map("n", "<leader>:", "<Cmd>Telescope command_history<CR>", {silent = true})
    map("n", "<leader>s", "<cmd>SidebarNvimToggle<cr>", {silent = true})

    -- タブ、バッファ操作
    map("n", "<leader>w", "<cmd>w<cr>", {silent = true})
    map("n", "<leader>q", "<cmd>q<cr>", {silent = true})
    map("n", "<leader>d", "<cmd>bd<cr>", {silent = true})
    map("n", "<leader>x", "<Cmd>tabclose<CR>", {silent = true})
    map("n", "<leader>c", '<cmd>enew<cr>', {silent = true})
    map("n", "<leader>t", '<cmd>tabnew<cr>', {silent = true})
    map("n", "<C-p>", '<cmd>tabp<cr>', {silent = true})
    map("n", "<C-n>", '<cmd>tabn<cr>', {silent = true})
    map("n", "<C-h>", "<cmd>bp<cr>", {silent = true})
    map("n", "<C-l>", "<cmd>bn<cr>", {silent = true})

    -- undotree
    map("n", "<leader>u", "<cmd>UndotreeToggle<cr>", {silent = true})

    -- 改行
    map("n", "<c-j>", "o<Esc>", {silent = true})
    map("n", "<c-k>", "O<Esc>", {silent = true})

    -- ウィンドウ操作
    map("n", "<C-w>e", "<cmd>vsplit<cr>")
    map("n", "<C-w>i", "<cmd>split<cr>")

    -- インデント
    map("n", ">", ">>")
    map("n", "<", "<<")
    map("v", ">", ">gv")
    map("v", "<", "<gv")

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

    -- float terminal
    map("n", "<A-d>", "<cmd>Lspsaga open_floaterm<cr>", {})
    map("t", "<A-d>", "<C-\\><C-n>:Lspsaga close_floaterm<cr>", {})

    -- lspsaga
    vim.api.nvim_create_autocmd({"FileType"}, {
        pattern = {"LspsagaFinder"},
        callback = function()
            buf_map(0, 'n', "<Esc>", "<cmd>lua require'lspsaga.provider'.close_lsp_finder_window()<cr>", { noremap = true })
        end,
    })
    vim.api.nvim_create_autocmd({"FileType"}, {
        pattern = {"LspsagaHover"},
        callback = function()
            buf_map(0, 'n', "<Esc>", "<cmd>q<cr>", { noremap = true })
            buf_map(0, 'n', "q", "<cmd>q<cr>", { noremap = true })
        end,
    })
    my_lsp_on_attach = function(client, bufnr)
        buf_map(0, "n", "gh", "<cmd>Lspsaga lsp_finder<cr>", {silent = true, noremap = true})
        buf_map(0, "n", "gd", "<cmd>Lspsaga preview_definition<cr>", {silent = true, noremap = true})
        buf_map(0, "n", "gs", "<cmd>Lspsaga signature_help<cr>", {silent = true, noremap = true})
        buf_map(0, "n", "gr", "<cmd>Lspsaga rename<cr>", {silent = true, noremap = true})
        buf_map(0, "n", "gx", "<cmd>Lspsaga code_action<cr>", {silent = true, noremap = true})
        buf_map(0, "x", "gx", "<cmd>Lspsaga range_code_action<cr>", {silent = true, noremap = true})
        buf_map(0, "n", "K",  "<cmd>Lspsaga hover_doc<cr>", {silent = true, noremap = true})
        buf_map(0, "n", "go", "<cmd>Lspsaga show_line_diagnostics<cr>", {silent = true, noremap = true})
        buf_map(0, "n", "gj", "<cmd>Lspsaga diagnostic_jump_next<cr>", {silent = true, noremap = true})
        buf_map(0, "n", "gk", "<cmd>Lspsaga diagnostic_jump_prev<cr>", {silent = true, noremap = true})
        buf_map(0, "n", "<C-u>", "<cmd>lua require('lspsaga.action').smart_scroll_with_saga(-1, '<c-u>')<cr>", {})
        buf_map(0, "n", "<C-d>", "<cmd>lua require('lspsaga.action').smart_scroll_with_saga(1, '<c-d>')<cr>", {})
        require("aerial").on_attach(client, bufnr)
    end

end
