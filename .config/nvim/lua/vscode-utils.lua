-- VSCode互換性用設定
-- VSCodeモードで無効化すべきプラグインの制御用モジュール

local M = {}

-- VSCodeモードかどうかをチェック
M.is_vscode = vim.g.vscode

-- VSCodeモードで無効にすべきプラグインの条件
-- 各プラグインのチェックに利用できる関数
function M.disabled_in_vscode()
    return M.is_vscode
end

-- VSCodeモードで特定の設定だけ無効にしたいプラグインの場合に利用
function M.should_use_native_in_vscode(plugin_name)
    if not M.is_vscode then
        return false
    end

    -- ここにVSCodeのネイティブ機能で代替できるプラグインを追加
    local native_alternatives = {
        -- UI関連
        ["neo-tree"] = true, -- エクスプローラー
        ["aerial"] = true, -- アウトライン
        ["gitsigns"] = true, -- Gitの差分表示
        ["telescope"] = true, -- ファイル検索
        ["heirline"] = true, -- ステータスライン
        ["bufferline"] = true, -- タブライン

        -- 編集機能関連
        ["toggleterm"] = true, -- ターミナル
        ["nvim-dap"] = true, -- デバッグ

        -- LSP関連
        ["lspsaga"] = true,    -- LSP UI
        ["nvim-lspconfig"] = true, -- LSP設定
        ["null-ls"] = true,    -- フォーマッタ
        ["mason"] = true,      -- LSPマネージャ
    }

    return native_alternatives[plugin_name] or false
end

return M
