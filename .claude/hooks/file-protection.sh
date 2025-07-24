#!/bin/bash

# Claude Code用ファイル保護フック
# 特定のファイルの参照、更新、削除を防ぐ

# 完全保護（読み込み・書き込み・削除すべて禁止）するファイルパターン
FULLY_PROTECTED_PATTERNS=(
    # 環境設定ファイル
    '\.env($|\..*)'
    '\.secrets?($|\..*)'

    # 認証情報・秘密鍵
    '\.ssh/'
    '.*\.(pem|key|cer|crt|p12|pfx)$'
    '.*\.credentials$'
    '.*\.token$'

    # AWS/クラウド認証情報
    '\.aws/credentials$'
    '\.aws/config$'
    'gcloud/.*\.json$'
    '\.azure/'
)

# 書き込み保護（読み込みは許可、書き込み・削除は禁止）するファイルパターン
WRITE_PROTECTED_PATTERNS=(
    # パッケージロックファイル
    'package-lock\.json$'
    'yarn\.lock$'
    'pnpm-lock\.yaml$'
    'Cargo\.lock$'
    'Gemfile\.lock$'
    'poetry\.lock$'

    # Gitディレクトリ
    '\.git/'

    # システムファイル
    '\.DS_Store$'
    'Thumbs\.db$'

    # バックアップファイル
    '.*\.(bak|backup|old)$'

    # ビルド成果物
    '/dist/'
    '/build/'
    '/target/'
    '/out/'
    '/\.next/'
    '/\.nuxt/'
    '/node_modules/'
    '/vendor/'
    '/__pycache__/'
    '\.pyc$'

    # IDEファイル
    '\.idea/'
    '\.vscode/settings\.json$'
    '\.vscode/launch\.json$'
    '\.vscode/tasks\.json$'
)

# 操作を許可するパターン（例外）
ALLOWED_PATTERNS=(
    # 例: テスト用の.envファイルは許可
    'test/.*\.env\.example$'
    '\.env\.example$'
    '\.env\.sample$'
)

# 標準入力からJSONを読み込む
json_input=$(cat)

# ツール名を取得
tool_name=$(echo "$json_input" | jq -r '.tool_name // ""')

# ファイルパスを取得（ツールによって異なる場所にある）
file_paths=""

case "$tool_name" in
"Read" | "Edit" | "Write" | "NotebookRead" | "NotebookEdit")
    # 単一ファイルパス
    file_paths=$(echo "$json_input" | jq -r '.tool_input.file_path // empty')
    ;;
"MultiEdit")
    # MultiEditの場合は単一ファイルパス
    file_paths=$(echo "$json_input" | jq -r '.tool_input.file_path // empty')
    ;;
"LS" | "Glob" | "Grep")
    # パスパラメータ
    file_paths=$(echo "$json_input" | jq -r '.tool_input.path // empty')
    ;;
"Bash")
    # Bashコマンドの場合、危険なコマンドをチェック
    command=$(echo "$json_input" | jq -r '.tool_input.command // ""')

    # rm, mv, cp などのファイル操作コマンドを検出
    if echo "$command" | grep -qE '(^|[;&|])\s*(rm|mv|cp|cat|less|more|head|tail|chmod|chown)\s+'; then
        # コマンドから対象ファイルを抽出する簡易的な方法
        # より詳細な解析が必要な場合は、より高度なパーサーを実装
        potential_files=$(echo "$command" | grep -oE '[^[:space:]]+\.(env|key|pem|lock)|\.git/[^[:space:]]+|node_modules/[^[:space:]]+' || true)
        if [ -n "$potential_files" ]; then
            file_paths="$potential_files"
        fi
    fi
    ;;
esac

# ファイルパスが空の場合は正常終了
if [ -z "$file_paths" ]; then
    exit 0
fi

# 完全保護対象かチェックする関数
is_fully_protected() {
    local file_path="$1"

    # 許可パターンに一致する場合は保護しない
    for pattern in "${ALLOWED_PATTERNS[@]}"; do
        if echo "$file_path" | grep -qE "$pattern"; then
            return 1
        fi
    done

    # 完全保護パターンに一致するかチェック
    for pattern in "${FULLY_PROTECTED_PATTERNS[@]}"; do
        if echo "$file_path" | grep -qE "$pattern"; then
            return 0
        fi
    done

    return 1
}

# 書き込み保護対象かチェックする関数
is_write_protected() {
    local file_path="$1"

    # 許可パターンに一致する場合は保護しない
    for pattern in "${ALLOWED_PATTERNS[@]}"; do
        if echo "$file_path" | grep -qE "$pattern"; then
            return 1
        fi
    done

    # 書き込み保護パターンに一致するかチェック
    for pattern in "${WRITE_PROTECTED_PATTERNS[@]}"; do
        if echo "$file_path" | grep -qE "$pattern"; then
            return 0
        fi
    done

    return 1
}

# 書き込み系ツールかチェック
is_write_tool() {
    case "$1" in
    "Edit" | "MultiEdit" | "Write" | "NotebookEdit")
        return 0
        ;;
    "Bash")
        # Bashコマンドの場合、書き込み系コマンドかチェック
        local cmd=$(echo "$json_input" | jq -r '.tool_input.command // ""')
        if echo "$cmd" | grep -qE '(^|[;&|])\s*(rm|mv|cp|chmod|chown|>|>>)\s+'; then
            return 0
        fi
        ;;
    esac
    return 1
}

# 各ファイルパスをチェック
# whileループのサブシェル問題を避けるため、終了ステータスを変数で管理
exit_status=0

while IFS= read -r file_path; do
    # 空の行はスキップ
    [ -z "$file_path" ] && continue

    # 完全保護対象のチェック（すべての操作を禁止）
    if is_fully_protected "$file_path"; then
        # エラーメッセージをJSON形式で出力
        cat >&2 <<EOF
{
  "decision": "block",
  "reason": "セキュリティポリシーにより、このファイルへのあらゆるアクセスが制限されています: $file_path"
}
EOF
        exit_status=2
        break
    fi

    # 書き込み保護対象のチェック（読み込みのみ許可）
    if is_write_protected "$file_path" && is_write_tool "$tool_name"; then
        # エラーメッセージをJSON形式で出力
        cat >&2 <<EOF
{
  "decision": "block",
  "reason": "このファイルは読み込み専用です。更新や削除は許可されていません: $file_path"
}
EOF
        exit_status=2
        break
    fi
done <<<"$file_paths"

# 設定された終了ステータスで終了
exit $exit_status
