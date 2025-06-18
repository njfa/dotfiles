local status_ok, vscode = pcall(require, "vscode")

local function vscode_mapping(function_native, function_vscode)
    if status_ok then
        return function_vscode
    else
        return function_native
    end
end

local function get_text()
    local visual = require("snacks.picker").util.visual()
    return visual and visual.text or ""
end

-- キーバインドをわかりやすくする
return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
        -- which-key.nvimの表示間隔を狭める
        vim.opt.timeout = true
        vim.opt.timeoutlen = 200
    end,
    config = function()
        local wk = require("which-key")
        local conform = require("conform")

        if status_ok then
            wk.add({
                {
                    mode = { "n" },
                    { "u",     vscode.action("undo"), desc = "Undo" },
                    { "<C-r>", vscode.action("redo"), desc = "Redo" },
                }
            })
        else
            wk.add({
                {
                    mode = { "n", "x" },
                    { "<A-s>", "<cmd>CodeCompanionChat Toggle<CR>", desc = "AIチャットを開く" },
                    { "<A-f>", function() require('telescope.builtin').grep_string() end, desc = "カーソル下/選択中の文字列をGrep検索" },

                    {
                        { "<leader>k", group = "AI機能" },
                        { "<leader>ke", group = "説明" },
                        { "<leader>kp", group = "修正案の作成" },
                        -- { "<leader>km", function() require('picker').select_strategy_and_model() end, desc = "使用するモデルを変更" },
                        { "<leader>kk", "<cmd>CodeCompanionActions<cr>", desc = "Actionsを起動" },
                        { "<leader>kc", "<cmd>CodeCompanion /commit_staged<cr>", desc = "コミットメッセージの作成 (Stagedのみ)" },
                        { "<leader>kC", "<cmd>CodeCompanion /commit_all<cr>", desc = "コミットメッセージの作成 (差分すべて)" },
                    },
                },
                {
                    mode = { "n" },
                   { "<leader>i", "<cmd>Neotree buffers float reveal<CR>", desc = "バッファ一覧を開く (floating window)" },
                   { "<A-m>", "<cmd>Mason<CR>", desc = "Masonを開く" },
        --            { "<leader>t", "<cmd>Telescope<CR>", desc = "Telescope機能一覧" },

                   {
                       { "<leader>k", group = "AI機能" },
                       { "<leader>kb", "ggVG:CodeCompanion /buffer ", desc = "バッファのInline Assistantを実行" },
                       { "<leader>kee", "ggVG:CodeCompanion /explain<cr>", desc = "コードの説明作成" },
                       { "<leader>ked", "ggVG:CodeCompanion /lsp<cr>", desc = "Diagnosticsの内容説明" },
                       { "<leader>kd", "ggVG:CodeCompanion /docs<cr>", desc = "コメントドキュメントの作成" },
                       { "<leader>kpd", "ggVG:CodeCompanion /fix_diagnostics<cr>", desc = "コードの修正案の作成 (Diagnostics利用)" },
                       { "<leader>kpp", "ggVG:CodeCompanion /fix_plan<cr>", desc = "コードの修正案の作成" },
                       { "<leader>kt", "ggVG:CodeCompanion /tests<cr>", desc = "テストコードの作成" },
                   },

                   {
                       { "<leader>x",  group = "Trouble" },
                       { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>",                             desc = "Diagnostics (Trouble)" },
                       { "<leader>xb", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",                desc = "Buffer Diagnostics (Trouble)" },
                       { "<leader>xs", "<cmd>Trouble symbols toggle focus=false win.position=bottom<cr>", desc = "Symbols (Trouble)" },
                       { "<leader>xl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",      desc = "LSP Definitions / references / ... (Trouble)" },
                       { "<leader>xq", "<cmd>Trouble qflist toggle<cr>",                                  desc = "Quickfix List (Trouble)" },
                       { "<leader>xL", "<cmd>Trouble loclist toggle<cr>",                                 desc = "Location List (Trouble)" },
                   },

                   {
                       { "<leader><leader>", group = "leader" },
                       { "<leader><leader>c", '<cmd>tabnew<cr>', desc = "タブ作成" },
                       { "<leader><leader>d", "<cmd>tabclose<CR>", desc = "タブを閉じる" },
                       {
                           "<leader><leader>e",
                           function()
                               require('neo-tree.command').execute({
                                   action = "focus",          -- OPTIONAL, this is the default value
                                   source = "filesystem",     -- OPTIONAL, this is the default value
                                   position = "left",         -- OPTIONAL, this is the default value
                                   toggle = true,
                                   dir = vim.fn.fnamemodify(require('common').get_cwd(), ":p"),
                                   reveal = true, -- path to file or folder to reveal
                                   reveal_force_cwd = false,   -- change cwd without asking if needed
                               })
                           end,
                           desc = "ファイラーを開く (left)",
                       },
                       { "<leader><leader>i", "<cmd>Neotree buffers bottom reveal toggle<CR>", desc = "バッファ一覧を開く (bottom)" },
        --                { "<leader><leader>h", "<cmd>lua require('telescope').extensions.frecency.frecency()<CR>", desc = "ファイル閲覧履歴 (頻度考慮)" },
                       { "<leader><leader>j", require('treesj').join, desc = "行結合" },
                       { "<leader><leader>J", require('treesj').split, desc = "行分割" },
                       { "<leader><leader>m", require('treesj').toggle, desc = "行分割/結合 切替" },
        --                { "<leader><leader>p", "<cmd>Telescope registers<CR>", desc = "クリップボード履歴" },
                       { "<leader><leader>r", [[:<c-u>%s/\v]], desc = "文字列置換 (正規表現)" },
                       { "<leader><leader>w", ":w ", desc = "ファイル名を付けて保存" },
                       { "<leader><leader>q", "<cmd>qa!<cr>", desc = "全ウィンドウを閉じる" },

                   },

        --            { "<F1>", "<cmd>lua require('telescope').extensions.dap.configurations{}<CR>", desc = "DAPの設定" },
        --            { "<F2>", "<cmd>lua require('telescope').extensions.dap.commands{}<CR>", desc = "DAPのコマンド一覧" },
        --            { "<F3>", "<cmd>lua require('telescope').extensions.dap.list_breakpoints{}<CR>", desc = "ブレークポイントの一覧" },
        --            { "<F4>", "<cmd>lua require('dap').set_breakpoint()<CR>", desc = "ブレークポイントの追加" },
        --            { "<F5>", "<cmd>lua require('dap').toggle_breakpoint()<CR>", desc = "ブレークポイントの切替" },
        --            { "<F6>", "<cmd>lua require('dap').step_into()<CR>", desc = "ステップ実行 (IN)" },
        --            { "<F7>", "<cmd>lua require('dap').continue()<CR>", desc = "実行" },
        --            { "<F8>", "<cmd>lua require('dap').step_over()<CR>", desc = "ステップ実行 (Over)" },
        --            { "<F9>", "<cmd>lua require('dap').step_out()<CR>", desc = "ステップ実行 (OUT)" },
        --            { "<F12>", "<cmd>lua require('dapui').toggle()<CR>", desc = "DAP UIの表示切替" },
                },
                {
                    mode = { "x" },
        --            { "gs", function() require('gitsigns').stage_hunk { vim.fn.line('.'), vim.fn.line('v') } end, desc = "Git stage hunk" },
        --            { "gr", function() require('gitsigns').reset_hunk { vim.fn.line('.'), vim.fn.line('v') } end, desc = "Git reset hunk" },

                    {
                        { "<leader>k", group = "AI機能" },
                        { "<leader>kb", [[:<c-u>'<,'>CodeCompanion /buffer ]], desc = "バッファのInline Assistantを実行" },
                        { "<leader>ka", "<cmd>CodeCompanionChat Add<cr>", desc = "AI Chatに選択範囲を貼り付ける" },
                        { "<leader>kee", "<cmd>CodeCompanion /explain<cr>", desc = "コードの説明作成" },
                        { "<leader>ked", "<cmd>CodeCompanion /lsp<cr>", desc = "Diagnosticsの内容説明" },
                        { "<leader>kd", "<cmd>CodeCompanion /docs<cr>", desc = "コメントドキュメントの作成" },
                        { "<leader>kpd", "<cmd>CodeCompanion /fix_diagnostics<cr>", desc = "コードの修正案の作成 (Diagnostics利用)" },
                        { "<leader>kpp", "<cmd>CodeCompanion /fix_plan<cr>", desc = "コードの修正案の作成" },
                        { "<leader>kt", "<cmd>CodeCompanion /tests<cr>", desc = "テストコードの作成" },
                    },

                    {
                        { "<leader>", group = "leader" },
                        { "<leader>f", function()
                            local text = get_text()
                            vscode_mapping(
                                Snacks.picker.files({ hidden=true, ignored=true, pattern=text }),
                                "workbench.action.quickOpen"
                            )
                        end, desc = "ファイル検索 (選択範囲の文字利用)" },
                        { "<leader>g", function()
                            local text = get_text()
                            vscode_mapping(Snacks.picker.grep({hidden=true, ignored=true, on_show = function()
                                vim.api.nvim_put({ text }, "c", true, true)
                            end}), "workbench.view.search")
                        end, desc = "Grep検索 (選択範囲の文字利用)" },
                    },
               },

               {
                   mode = { "i", "s" },
                   { "<C-j>", function() require('luasnip').jump(1) end, desc = "次の要素へ移動" },
                   { "<C-k>", function() require('luasnip').jump(-1) end, desc = "前の要素へ移動" },
                   {
                       "<C-c>",
                       function()
                           if require('luasnip').choice_active() then
                               require('luasnip').change_choice(1)
                           end
                       end,
                       desc = "選択中の要素を変更"
                   },
                },

                {
                    mode = { "i" },
                    { "<C-e>", function() require('luasnip').expand() end, desc = "スニペットの展開" },
                    {
                        "<C-l>",
                        function()
                            local line = vim.fn.getline(".")
                            local col = vim.fn.getpos(".")[3]
                            local substring = line:sub(1, col - 1)
                            local result = vim.fn.matchstr(substring, [[\v<(\k(<)@!)*$]])
                            return "<C-w>" .. result:upper()
                        end,
                        expr = true,
                        desc = "直前の入力を大文字へ変換"
                    }
                },
            })
        end

        wk.add({
            {
                mode = { "n", "x" },

                { "s", '"_s', desc = "s (レジスタを書き換えない)" },
                { "x", '"_x', desc = "x (レジスタを書き換えない)" },
                { "n", 'nzz', desc = "次の検索結果へ" },
                { "N", 'Nzz', desc = "前の検索結果へ" },

                { ")", function() require('hop').hint_lines_skip_whitespace({}) end, desc = "任意の行頭へ移動（空行は無視）" },
                {
                    "t",
                    function()
                        require('hop').hint_camel_case({
                            current_line_only = false,
                            hint_position = require 'hop.hint'
                            .HintPosition.BEGIN
                        })
                    end,
                    desc = "任意の単語へ移動"
                },
                {
                    "T",
                    function()
                       require('hop').hint_camel_case({
                            current_line_only = false,
                            hint_position = require 'hop.hint'
                            .HintPosition.END
                        })
                    end,
                    desc = "任意の単語へ移動"
                },
                { "<Up>", "<cmd>HopVerticalBC<cr>", desc = "任意の行へ移動（上）" },
                { "<Down>", "<cmd>HopVerticalAC<cr>", desc = "任意の行へ移動（下）" },
                {
                    { "m", group = "ファイル編集" },
                    { "mm", "<cmd>Switch<cr>", desc = "カーソル下の単語を反転 (true→false等)" },
                },

                {
                    { "s", group = "Sandwich" },
                    { "sa", [[<Plug>(operator-sandwich-add)]], desc = "Sandwich add" },
                    { "sd", [[<Plug>(operator-sandwich-delete)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-query-a)]], desc = "Sandwich delete" },
                    { "sr", [[<Plug>(operator-sandwich-replace)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-query-a)]], desc = "Sandwich replace" },
                    { "m=", function() conform.format({ lsp_fallback = true, async = false, timeout_ms = 5000, }) end, desc = "ファイル(normal)/範囲(visual)の整形" },
                },
                {
                    { "<leader><leader>t", group = "Table操作" },
                    { "<leader><leader>tm", "<cmd>TableModeToggle<CR>", desc = "Tableモード切替" },
                    { "<leader><leader>ta", "<cmd>TableModeRealign<CR>", desc = "Table整形" },
                    { "<leader><leader>tt", [[<Plug>(table-mode-tableize)]], desc = "Tableへ変換" },
                }
            },
            {
                mode = { "n" },
                { "0", "^", desc = "行の先頭文字に移動" },
                { "^", "0", desc = "行頭に移動" },

                {
                    "<leader>q",
                    vscode_mapping(
                        "<cmd>q<cr>",
                        function()
                            vscode.action("workbench.action.closeActiveEditor")
                        end
                    ),
                    desc = "ウィンドウを閉じる",
                },

                { "<C-Up>", '"zdd<Up>"zP', desc = "カーソル行を1行移動 (上)" },
                { "<C-Down>", '"zdd"zp', desc = "カーソル行を1行移動 (下)" },

                { "<C-j>", 'o<Esc>0"_D', desc = "空行を挿入 (下)" },
                { "<C-k>", 'O<Esc>0"_D', desc = "空行を挿入 (上)" },

                { "*", [[<Plug>(asterisk-z*)<Cmd>lua require('hlslens').start()<CR>]], desc = "* (カーソルを移動しない)" },
                { "#", [[<Plug>(asterisk-z#)<Cmd>lua require('hlslens').start()<CR>]], desc = "# (カーソルを移動しない)" },
                { "g*", [[<Plug>(asterisk-gz*)<Cmd>lua require('hlslens').start()<CR>]], desc = "g* (カーソルを移動しない)" },
                { "g#", [[<Plug>(asterisk-gz#)<Cmd>lua require('hlslens').start()<CR>]], desc = "g# (カーソルを移動しない)" },

                { "{", "<cmd>cp<CR>zz", desc = "quickfixの前の要素に移動する" },
                { "}", "<cmd>cn<CR>zz", desc = "quickfixの次の要素に移動する" },

                { "gb", "<cmd>Gitsigns toggle_current_line_blame<cr>", desc = "Git blameの表示切替" },
                { "gh", "<cmd>GitMessenger<cr>", desc = "Git履歴表示" },

                {
                    { "me", group = "ナンバリング" },
                    { "mes", "<cmd>SetHeaderNumber<cr>", desc = "ナンバリングを適用" },
                    { "meu", "<cmd>UnsetHeaderNumber<cr>", desc = "ナンバリングを削除" },
                    { "met", "<cmd>ToggleHeaderNumber<cr>", desc = "ナンバリングを切替" },
                },
                { "R", function() require('substitute').operator() end, desc = "指定したテキストオブジェクトを置換" },


                { "<Esc>", ":noh<cr>", desc = "検索結果のハイライトを削除" },

                { "H", "<cmd>tabp<cr>", desc = "前のタブに移動" },
                { "L", "<cmd>tabn<cr>", desc = "次のタブに移動" },
                { "<C-h>", vscode_mapping("<cmd>BufferLineCyclePrev<cr>", "<cmd>Tabprevious<cr>"), desc = "前のバッファに移動" },
                { "<C-l>", vscode_mapping("<cmd>BufferLineCycleNext<cr>", "<cmd>Tabnext<cr>"), desc = "次のバッファに移動" },

                {
                    { "<C-w>", group = "画面操作" },
                    {
                        "<C-w>e",
                        vscode_mapping(
                            "<cmd>vsplit<cr>",
                            function()
                                vscode.action(
                                    "workbench.action.splitEditor"
                                )
                            end
                        ),
                        desc = "画面分割 (縦)"
                    },
                    {
                        "<C-w>i",
                        vscode_mapping(
                            "<cmd>split<cr>",
                            function()
                                vscode.action(
                                    "workbench.action.splitEditorOrthogonal"
                                )
                            end
                        ),
                        desc = "画面分割 (横)"
                    },
                    {
                        "<C-w>p",
                        vscode_mapping(
                            "<cmd>MarkdownPreview<cr>",
                            function()
                                vscode.action(
                                    "markdown.showPreviewToSide"
                                )
                            end
                        ),
                        desc = "Markdownのプレビュー"
                    },
                    {
                        "<C-w>g",
                        vscode_mapping(
                            "<cmd>DiffviewFileHistory<cr>",
                            function()
                                vscode.action(
                                    "gitlens.openFileHistory"
                                )
                            end
                        ),
                        desc = "GitのDiff表示領域を表示",
                    },
                },

                {
                    { "<leader>", group = "leader" },
                    {
                        "<leader>c",
                        vscode_mapping('<cmd>enew<cr>', function()
                            vscode.action(
                                "workbench.action.files.newUntitledFile")
                        end),
                        desc = "バッファ作成"
                    },
                    { "<leader>p", "<cmd>HopPasteChar1<CR>", desc = "貼り付け（場所選択）" },
                    { "<leader>r", [[:<c-u>%s/]], desc = "文字列置換" },
                   {
                       "<leader>U",
                       vscode_mapping("<cmd>UndotreeToggle<cr>", function()
                           vscode.action(
                               "timeline.focus")
                       end),
                       desc = "ファイル編集履歴 表示切替"
                   },
                   { "<leader>w", "<cmd>w<cr>", desc = "保存" },
                   { "<leader>y", "<cmd>HopYankChar1<CR>", desc = "コピー（場所選択）" },

                   { "<leader>m", function() require('treesj').toggle({ split = { recursive = true } }) end, desc = "行分割/結合 切替" },
                   { "<leader>j", function() require('treesj').join({ join = { recursive = false } }) end, desc = "行結合" },
                   { "<leader>J", function() require('treesj').split({ split = { recursive = true } }) end, desc = "行分割" },

                   {
                       "<leader>e",
                       vscode_mapping(
                           function()
                               require('neo-tree.command').execute({
                                   action = "focus",          -- OPTIONAL, this is the default value
                                   source = "filesystem",     -- OPTIONAL, this is the default value
                                   position = "float",         -- OPTIONAL, this is the default value
                                   toggle = true,
                                   dir = vim.fn.fnamemodify(require('common').get_cwd(), ":p"),
                                   reveal = true, -- path to file or folder to reveal
                                   reveal_force_cwd = false,   -- change cwd without asking if needed
                               })
                           end,
                           function(
                           )
                               vscode.action(
                                   "workbench.explorer.fileView.focus"
                               )
                           end
                       ),
                       desc = "ファイラーを開く (floating window)",
                   },

                    {
                        { "<leader>.", group = "設定変更" },
                        {
                            "<leader>.t",
                            function()
                                vim.bo.expandtab = not (vim.bo.expandtab)
                                vim.notify("インデント文字: " .. (vim.bo.expandtab and "space" or "tab"))
                            end,
                            desc = "インデント文字の切替 (space <-> tab)",
                        },
                        {
                            "<leader>.o",
                            vscode_mapping(
                                function()
                                    if vim.bo.modifiable then
                                        if vim.bo.fileformat == "unix" then
                                            vim.bo.fileformat = "dos"
                                            vim.notify("改行文字: CRLF")
                                        else
                                            vim.bo.fileformat = "unix"
                                            vim.notify("改行文字: LF")
                                        end
                                    else
                                        vim.notify("このファイルは編集可能なファイルではありません")
                                    end
                                end,
                                function()
                                    vscode.action("workbench.action.editor.changeEncoding")
                                end
                            ),
                            desc = "ファイルタイプの切替 (unix <-> dos)",
                        },
                        {
                            "<leader>.w",
                            vscode_mapping(
                                function()
                                    vim.bo.shiftwidth = (vim.bo.shiftwidth % 4) + 2
                                    vim.notify("インデント幅: " .. tostring(vim.bo.shiftwidth))
                                end,
                                function()
                                    vscode.action("notebook.selectIndentation")
                                end
                            ),
                            desc = "インデント幅の変更 (2 <-> 4)",
                        },
                        {
                            "<leader>.f",
                            vscode_mapping(
                                "<cmd>Telescope filetypes<CR>",
                                function()
                                    vscode.action("workbench.action.editor.changeLanguageMode")
                                end
                            ),
                            desc = "ファイルタイプの変更"
                        }
                    },
                },
            },

            {
                mode = { "x" },
                { "p", 'pgvy', desc = "p (レジスタを書き換えない)" },
                { "P", 'Pgvy', desc = "P (レジスタを書き換えない)" },

                { ">", ">gv", desc = "インデントを上げる (選択範囲を維持)" },
                { "<", "<gv", desc = "インデントを下げる (選択範囲を維持)" },

                { "<C-a>", "<C-a>gv", desc = "<C-a> (選択範囲を維持)" },
                { "<C-x>", "<C-x>gv", desc = "<C-x> (選択範囲を維持)" },

                { "<C-Up>", '"zx<Up>"zP`[V`]', desc = "カーソル行を1行移動 (上)" },
                { "<C-Down>", '"zx"zp`[V`]', desc = "カーソル行を1行移動 (下)" },

               { "*", [[<Plug>(asterisk-z*)<Cmd>lua require('hlslens').start()<CR>gv]], desc = "* (カーソルを移動しない)" },
               { "#", [[<Plug>(asterisk-z#)<Cmd>lua require('hlslens').start()<CR>gv]], desc = "# (カーソルを移動しない)" },
               { "g*", [[<Plug>(asterisk-gz*)<Cmd>lua require('hlslens').start()<CR>gv]], desc = "g* (カーソルを移動しない)" },
               { "g#", [[<Plug>(asterisk-gz#)<Cmd>lua require('hlslens').start()<CR>gv]], desc = "g# (カーソルを移動しない)" },

               { "<cr>", "<Plug>(EasyAlign)", desc = "指定文字で整列 (*で全一致箇所)" },
               { "<Bar>", ":EasyAlign*<Bar><CR>", desc = "|で整形" },

               { "v", ":lua require('tsht').nodes()<cr>", desc = "選択範囲を拡大" },
               { "R", function() require "substitute".visual() end, desc = "選択範囲を置換" },

                {
                    { "<leader>", group = "leader" },
                    { "<leader>r", [[:<c-u>'<,'>s/]], desc = "文字列置換" },
                    { "<leader><leader>r", [[:<c-u>'<,'>s/\v]], desc = "文字列置換 (正規表現)" },
                },
            },

           {
               mode = { "o" },
               { "r", function() require("flash").remote() end, desc = "Remote Flash" },
           },

           {
               mode = { "o", "x" },
               { "R", function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
           }
        })

        wk.setup({
            preset = "modern",
            triggers = {
                { "<auto>", mode = "nixsotc" },
                { "m",      mode = { "n", "v" } },
                { "<C-w>",  mode = { "n" } },
            },
            -----@param ctx { mode: string, operator: string }
            defer = function(ctx)
                if status_ok then
                    return false
                end

                return vim.list_contains({ "s", "v", "<C-V>", "V" }, ctx.mode)
            end,
            win = {
                no_overlap = true,
                -- border = "double",
                wo = {
                    winblend = 10, -- value between 0-100 0 for fully opaque and 100 for fully transparent
                },
                -- margin = { 1, 0.1, 2, 0.1 }, -- extra window margin [top, right, bottom, left]. When between 0 and 1, will be treated as a percentage of the screen size.
                padding = { 1, 0, 1, 0 }, -- extra window padding [top, right, bottom, left]
            },
            layout = {
                height = { min = 4, max = 25 }, -- min and max height of the columns
                width = { min = 10, max = 50 }, -- min and max width of the columns
                spacing = 3,                    -- spacing between columns
                align = "center",               -- align columns left, center or right
            },
            replace = {
                ["<leader>"] = "SPACE",
                ["<cr>"] = "ENTER",
                ["<tab>"] = "TAB",
                ["<esc>"] = "ESCAPE",
            },
        })
    end
}
