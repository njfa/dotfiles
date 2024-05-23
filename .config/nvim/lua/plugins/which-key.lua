-- キーバインドをわかりやすくする
return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function ()
        -- which-key.nvimの表示間隔を狭める
        vim.opt.timeout = true
        vim.opt.timeoutlen = 200
    end,
    config = function()
        local wk = require("which-key")
        local hop = require('hop')

        wk.register({
            ["0"] = { "^", "行の先頭文字に移動" },
            ["^"] = { "0", "行頭に移動" },

            ["<C-Up>"] = { '"zdd<Up>"zP', "カーソル行を1行移動 (上)" },
            ["<C-Down>"] = { '"zdd"zp', "カーソル行を1行移動 (下)" },

            ["ys"] = { [[<Plug>(operator-sandwich-add)]], "Sandwich add" },
            ["ds"] = { [[<Plug>(operator-sandwich-delete)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-query-a)]], "Sandwich delete" },
            ["cs"] = { [[<Plug>(operator-sandwich-replace)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-query-a)]], "Sandwich replace" },

            ["<C-j>"] = { 'o<Esc>0"_D', "空行を挿入 (下)" },
            ["<C-k>"] = { 'O<Esc>0"_D', "空行を挿入 (上)" },

            s = { '"_s', "s (レジスタを書き換えない)" },
            x = { '"_x', "x (レジスタを書き換えない)" },

            ["*"] = { [[<Plug>(asterisk-z*)<Cmd>lua require('hlslens').start()<CR>]], "* (カーソルを移動しない)" },
            ["#"] = { [[<Plug>(asterisk-z#)<Cmd>lua require('hlslens').start()<CR>]], "# (カーソルを移動しない)" },
            g = {
                ["*"] = { [[<Plug>(asterisk-gz*)<Cmd>lua require('hlslens').start()<CR>]], "g* (カーソルを移動しない)" },
                ["#"] = { [[<Plug>(asterisk-gz#)<Cmd>lua require('hlslens').start()<CR>]], "g# (カーソルを移動しない)" },
            },

            L = { function() hop.hint_lines_skip_whitespace({ }) end, "任意の行頭へ移動（空行は無視）" },
            H = { function() hop.hint_lines({ }) end, "任意の行頭へ移動" },
            t = { function() hop.hint_camel_case({ current_line_only = false }) end, "任意の単語へ移動" },
            f = { function() hop.hint_char1({ current_line_only = true }) end, "指定文字へ移動 (行中)" },
            F = { function() hop.hint_char1({ current_line_only = false }) end, "指定文字へ移動 (全体)" },

            m = {
                a = { "<Plug>(EasyAlign)", "指定文字で整列 (*で全一致箇所)"},
                s = { "<cmd>Switch<cr>", "カーソル下の単語を反転 (true→false等)"},
                g = { "<cmd>GitMessenger<cr>", "Git履歴表示"},
            },

            R = { function() require('substitute').operator() end, {}, "指定したテキストオブジェクトを置換" },

            ["<Esc>"] = { ":noh<cr>", "検索結果のハイライトを削除" },

            ["<A-s>"] = { "<cmd>Fern . -reveal=% -drawer -toggle<cr>", "ファイルツリーの表示切替" },

            ["<C-p>"] = { "<cmd>tabp<cr>", "前のタブに移動" },
            ["<C-n>"] = { "<cmd>tabn<cr>", "次のタブに移動" },

            ["<C-h>"] = { "<cmd>BufferLineCyclePrev<cr>", "前のバッファに移動" },
            ["<C-l>"] = { "<cmd>BufferLineCycleNext<cr>", "次のバッファに移動" },

            ["<C-w>"] = {
                e = { "<cmd>vsplit<cr>", "画面分割 (縦)" },
                i = { "<cmd>split<cr>", "画面分割 (横)" },
                p = { "<cmd>MarkdownPreview<cr>", "Markdownのプレビュー" },
                d = { "<cmd>DiffviewFileHistory<cr>", "GitのDiff表示領域を表示" },
                ["."] = { function() require("common").lcd_current_workspace() end, "vimのカレントディレクトリを変更" },
            },

            ["<leader>"] = {
                name = "コマンド (利用頻度: 高)",
                b = { "<cmd>Telescope buffers<CR>", "バッファ一覧" },
                c = { '<cmd>enew<cr>', "バッファ作成" },
                d = { "<cmd>bp<bar>sp<bar>bn<bar>bd!<cr>", "バッファを閉じる" },
                e = { "<cmd>Telescope projects<CR>", "プロジェクト一覧" },
                f = { function() require('picker').find_files_from_project_git_root() end, "ファイル検索" },
                g = { function() require('picker').live_grep_from_project_git_root() end, "Grep検索"},
                h = { function() require('picker').find_files_from_project_git_root({oldfiles= true}) end, "ファイル閲覧履歴" },
                i = { function() require('telescope.builtin').diagnostics({ bufnr=0 }) end, "Diagnostics (バッファ内)" },
                m = { function() require('treesj').toggle({ split = { recursive = true } }) end, "行分割/結合 切替" },
                j = { function() require('treesj').join({ join = { recursive = false } }) end, "行結合" },
                s = { function() require('treesj').split({ split = { recursive = true } }) end, "行分割" },
                p = { "<cmd>HopPasteChar1<CR>", "貼り付け（場所選択）" },
                r = { [[:<c-u>%s/]], "文字列置換"},
                t = { "<cmd>Telescope<CR>", "Telescope機能一覧" },
                u = { "<cmd>UndotreeToggle<cr>", "ファイル編集履歴 表示切替" },
                w = { "<cmd>w<cr>", "保存" },
                q = { "<cmd>q<cr>", "ウィンドウを閉じる" },
                x = {
                    name = "コマンド (Diagnostics表示)",
                    x = { function() require("trouble").toggle() end, "表示切替" },
                    w = { function() require("trouble").toggle("workspace_diagnostics") end, "Diagnostics (ワークスペース内)" },
                    d = { function() require("trouble").toggle("document_diagnostics")  end, "Diagnostics (ドキュメント内)" },
                },
                y = { "<cmd>HopYankChar1<CR>", "コピー（場所選択）" },
                ["/"] = { "<cmd>Telescope current_buffer_fuzzy_find<CR>", "バッファ内検索" },
                [":"] = { function() require('picker').command_history() end, "コマンド履歴" },
                ["."] = { function() require('reload').reload() end, "Neovim設定ファイル一覧" },
                ["<leader>"] = {
                    name = "コマンド (利用頻度: 中)",
                    b = { "<cmd>BufferLinePick<CR>", "タブ指定移動" },
                    c = { '<cmd>tabnew<cr>', "タブ作成" },
                    d = { "<cmd>tabclose<CR>", "タブを閉じる" },
                    f = { ":lua require('picker').find_files_from_project_git_root( { search_file=\"\" })<left><left><left><left>", "ファイル検索 (ファイルパスを指定)" },
                    g = { ":lua require('picker').live_grep_from_project_git_root( { glob_pattern=\"\" })<left><left><left><left>", "Grep検索 (ファイルパスを指定)" },
                    h = { "<cmd>lua require('telescope').extensions.frecency.frecency()<CR>", "ファイル閲覧履歴 (頻度考慮)" },
                    i = { "<cmd>lua require('telescope.builtin').diagnostics({})<CR>", "Diagnostics (プロジェクト全体)" },
                    j = { require('treesj').join, "行結合" },
                    m = { require('treesj').toggle, "行分割/結合 切替" },
                    s = { require('treesj').split, "行分割" },
                    p = { "<cmd>Telescope registers<CR>", "クリップボード履歴" },
                    r = { [[:<c-u>%s/\v]], "文字列置換 (正規表現)"},
                    t = {
                        name = "コマンド (Todo一覧 / Tableモード)",
                        l = { "<cmd>TodoTelescope<CR>", "TODO一覧" },
                        m = { "<cmd>TableModeToggle<CR>", "Tableモード切替" },
                        t = { [[<Plug>(table-mode-tableize)]], "Tableへ変換" },
                    },
                    w = { ":w ", "ファイル名を付けて保存" },
                    q = { "<cmd>qa!<cr>", "全ウィンドウを閉じる" },
                }
            },
            ['<F1>'] = { "<cmd>lua require('telescope').extensions.dap.configurations{}<CR>", "DAPの設定" },
            ['<F2>'] = { "<cmd>lua require('telescope').extensions.dap.commands{}<CR>", "DAPのコマンド一覧" },
            ['<F3>'] = { "<cmd>lua require('telescope').extensions.dap.list_breakpoints{}<CR>", "ブレークポイントの一覧" },
            ['<F4>'] = { "<cmd>lua require('dap').set_breakpoint()<CR>", "ブレークポイントの追加" },
            ['<F5>'] = { "<cmd>lua require('dap').toggle_breakpoint()<CR>", "ブレークポイントの切替" },
            ['<F6>'] = { "<cmd>lua require('dap').step_into()<CR>", "ステップ実行 (IN)" },
            ['<F7>'] = { "<cmd>lua require('dap').continue()<CR>", "実行" },
            ['<F8>'] = { "<cmd>lua require('dap').step_over()<CR>", "ステップ実行 (Over)" },
            ['<F9>'] = { "<cmd>lua require('dap').step_out()<CR>", "ステップ実行 (OUT)" },
            ['<F12>'] = { "<cmd>lua require('dapui').toggle()<CR>", "DAP UIの表示切替" },
        }, {
            mode = "n"
        })

        wk.register({
            s = { '"_s', "s (レジスタを書き換えない)" },
            x = { '"_x', "x (レジスタを書き換えない)" },
            p = { 'pgvy', "p (レジスタを書き換えない)" },
            P = { 'Pgvy', "P (レジスタを書き換えない)" },

            [">"] = { ">gv", "インデントを上げる (選択範囲を維持)" },
            ["<"] = { "<gv", "インデントを下げる (選択範囲を維持)" },

            ["<C-a>"] = { "<C-a>gv", "<C-a> (選択範囲を維持)" },
            ["<C-x>"] = { "<C-x>gv", "<C-x> (選択範囲を維持)" },

            ["<C-Up>"] = { '"zx<Up>"zP`[V`]', "カーソル行を1行移動 (上)" },
            ["<C-Down>"] = { '"zx"zp`[V`]', "カーソル行を1行移動 (下)" },

            ["*"] = { [[<Plug>(asterisk-z*)<Cmd>lua require('hlslens').start()<CR>gv]], "* (カーソルを移動しない)" },
            ["#"] = { [[<Plug>(asterisk-z#)<Cmd>lua require('hlslens').start()<CR>gv]], "# (カーソルを移動しない)" },
            g = {
                ["*"] = { [[<Plug>(asterisk-gz*)<Cmd>lua require('hlslens').start()<CR>gv]], "g* (カーソルを移動しない)" },
                ["#"] = { [[<Plug>(asterisk-gz#)<Cmd>lua require('hlslens').start()<CR>gv]], "g# (カーソルを移動しない)" },
            },

            L = { function() hop.hint_lines_skip_whitespace({ }) end, "任意の行頭へ移動" },
            H = { function() hop.hint_anywhere({}) end, "任意の場所へ移動" },
            t = { function() hop.hint_words({ current_line_only = false }) end, "任意のWordへ移動" },
            f = { function() hop.hint_char1({ current_line_only = true }) end, "指定文字へ移動 (行中)" },
            F = { function() hop.hint_char1({ current_line_only = false }) end, "指定文字へ移動 (全体)" },
            v = { ":lua require('tsht').nodes()<cr>", "選択範囲を拡大" },

            m = {
                a = { "<Plug>(EasyAlign)", "指定文字で整列 (*で全一致箇所)"},
                s = { "<cmd>Switch<cr>", "カーソル下の単語を反転 (true→false等)"},
            },

            R = { function() require"substitute".visual() end, "選択範囲を置換" },

            ["<Bar>"] = { ":EasyAlign*<Bar><CR>", "|で整形" },
            ["<leader>"] = {
                name = "コマンド (利用頻度: 高)",
                f = { function() require('picker').find_files_string_visual() end, "ファイル検索 (選択範囲の文字利用)" },
                g = { function() require('picker').grep_string_visual() end, "Grep検索 (選択範囲の文字利用)" },
                r = { [[:<c-u>'<,'>s/]], "文字列置換" },
                ["<leader>"] = {
                    name = "コマンド (利用頻度: 中)",
                    t = {
                        name = "コマンド (TODO一覧 / Tableモード)",
                        l = { "<cmd>TodoTelescope<CR>", "TODO一覧" },
                        m = { "<cmd>TableModeToggle<CR>", "Tableモード切替" },
                        t = { [[<Plug>(table-mode-tableize)]], "Tableへ変換" },
                    },
                    r = { [[:<c-u>'<,'>s/\v]], "文字列置換 (正規表現)" },
                }
            }
        }, {
            mode = "x"
        })

        -- wk.register({
        --     ['<C-e>'] = { function() require('luasnip').expand() end, "スニペットの展開"},
        --     ['<C-j>'] = { function() require('luasnip').jump(1) end, "次の要素へ移動"},
        --     ['<C-k>'] = { function() require('luasnip').jump(-1) end, "前の要素へ移動"},
        --     ['<C-c>'] = { function()
        --         if require('luasnip').choice_active() then
        --             require('luasnip').change_choice(1)
        --         end
        --     end, "選択中の要素を変更"},
        -- }, {
        --     mode = "i"
        -- })

        -- wk.register({
        --     ['<C-j>'] = { function() require('luasnip').jump(1) end, "次の要素へ移動"},
        --     ['<C-k>'] = { function() require('luasnip').jump(-1) end, "前の要素へ移動"},
        --     ['<C-c>'] = { function()
        --         if require('luasnip').choice_active() then
        --             require('luasnip').change_choice(1)
        --         end
        --     end, "選択中の要素を変更"},
        -- }, {
        --     mode = "s"
        -- })
        --

        wk.setup({
            window = {
                border = "double",
                winblend = 10, -- value between 0-100 0 for fully opaque and 100 for fully transparent
                margin = { 1, 0.1, 2, 0.1 }, -- extra window margin [top, right, bottom, left]. When between 0 and 1, will be treated as a percentage of the screen size.
                padding = { 1, 0, 1, 0 }, -- extra window padding [top, right, bottom, left]
            },
            layout = {
                height = { min = 4, max = 25 }, -- min and max height of the columns
                width = { min = 10, max = 50 }, -- min and max width of the columns
                spacing = 3, -- spacing between columns
                align = "center", -- align columns left, center or right
            },
            key_labels = {
                ["<leader>"] = "SPACE",
                ["<cr>"] = "ENTER",
                ["<tab>"] = "TAB",
                ["<esc>"] = "ESCAPE",
            },
        })
        end
    }
