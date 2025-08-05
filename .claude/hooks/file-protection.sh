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

# プロダクションコードかチェックする関数
is_product_code() {
    local file_path="$1"

    # テストコードパターンに一致する場合はプロダクションコードではない
    if is_test_code "$file_path"; then
        return 1
    fi

    # プロダクションコードのパターン
    # src/ディレクトリ内のファイル
    if echo "$file_path" | grep -qE '/src/.*\.(js|ts|jsx|tsx|py|java|go|rs|cpp|c|h|hpp)$'; then
        return 0
    fi

    # lib/ディレクトリ内のファイル
    if echo "$file_path" | grep -qE '/lib/.*\.(js|ts|jsx|tsx|py|java|go|rs|cpp|c|h|hpp)$'; then
        return 0
    fi

    # app/ディレクトリ内のファイル (Rails, Next.js等)
    if echo "$file_path" | grep -qE '/app/.*\.(js|ts|jsx|tsx|py|rb|java|go|rs|cpp|c|h|hpp)$'; then
        return 0
    fi

    # components/ディレクトリ内のファイル
    if echo "$file_path" | grep -qE '/components/.*\.(js|ts|jsx|tsx|vue)$'; then
        return 0
    fi

    # pages/ディレクトリ内のファイル (Next.js等)
    if echo "$file_path" | grep -qE '/pages/.*\.(js|ts|jsx|tsx)$'; then
        return 0
    fi

    # プロジェクトルートレベルの主要ファイル（テストファイルでない場合）
    if echo "$file_path" | grep -qE '\.(js|ts|jsx|tsx|py|java|go|rs|cpp|c|h|hpp|rb)$' && ! echo "$file_path" | grep -qE '(test|spec|__tests__|\.test\.|\.spec\.)'; then
        return 0
    fi

    return 1
}

# テストコードかチェックする関数
is_test_code() {
    local file_path="$1"

    # テストコードのパターン
    # test/ディレクトリ内のファイル
    if echo "$file_path" | grep -qE '/tests?/.*\.(js|ts|jsx|tsx|py|java|go|rs|cpp|c|h|hpp|rb)$'; then
        return 0
    fi

    # __tests__/ディレクトリ内のファイル (Jest等)
    if echo "$file_path" | grep -qE '/__tests__/.*\.(js|ts|jsx|tsx)$'; then
        return 0
    fi

    # spec/ディレクトリ内のファイル (RSpec等)
    if echo "$file_path" | grep -qE '/spec/.*\.(rb|js|ts|jsx|tsx|py)$'; then
        return 0
    fi

    # .test. または .spec. を含むファイル
    if echo "$file_path" | grep -qE '\.test\.(js|ts|jsx|tsx|py|java|go|rs|cpp|c|h|hpp|rb)$'; then
        return 0
    fi

    if echo "$file_path" | grep -qE '\.spec\.(js|ts|jsx|tsx|py|java|go|rs|cpp|c|h|hpp|rb)$'; then
        return 0
    fi

    # _test.py (Python)
    if echo "$file_path" | grep -qE '_test\.py$'; then
        return 0
    fi

    # test_*.py (Python)
    if echo "$file_path" | grep -qE 'test_.*\.py$'; then
        return 0
    fi

    # *Test.java (Java)
    if echo "$file_path" | grep -qE '.*Test\.java$'; then
        return 0
    fi

    # *_test.go (Go)
    if echo "$file_path" | grep -qE '.*_test\.go$'; then
        return 0
    fi

    return 1
}

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
        if echo "$cmd" | grep -qE '(^|[;&|]).*[[:space:]]*(rm|mv|cp|chmod|chown|>|>>)[[:space:]]+'; then
            return 0
        fi
        ;;
    esac
    return 1
}

# 標準入力からJSONを読み込む
json_input=$(cat)

# transcript_pathを取得
transcript_path=$(echo "$json_input" | jq -r '.transcript_path // empty')
# json_inputのセッションIDは`session_id`で記録され、transcript_path中のセッションIDは`sessionId`で記録される
session_id=$(echo "$json_input" | jq -r '.session_id // empty')

# transcript_pathが存在する場合の処理
if [ "$(echo "$CLAUDE_OPERATION_TYPE_VALIDATION" | tr '[:upper:]' '[:lower:]')" = "true" ] && [ -n "$transcript_path" ] && [ -f "$transcript_path" ] && [ -n "$session_id" ]; then
    # transcript_pathから同一sessionIdのfile_pathを含む要素を時系列順で抽出
    transcript_file_paths=$(jq -r --arg session_id "$session_id" '
        select(.sessionId == $session_id and .message.content?) |
        .message.content[] |
        select(.type == "tool_use" and (.name == "Write" or .name == "Edit" or .name == "MultiEdit") and .input.file_path?) |
        .input.file_path
    ' "$transcript_path" 2>/dev/null)

    if [ -n "$transcript_file_paths" ]; then
        # プロダクションコードかテストコードかを判定
        transcript_file_type=""
        while IFS= read -r transcript_file; do
            [ -z "$transcript_file" ] && continue

            if is_product_code "$transcript_file"; then
                if [ "$transcript_file_type" = "test" ]; then
                    # 混在している場合はエラー
                    echo "{\"hookSpecificOutput\": { \"hookEventName\": \"PreToolUse\", \"permissionDecision\": \"deny\", \"permissionDecisionReason\": \"テストコードの操作後、プロダクションコードを操作することは禁止しています\"}}" | jq -rc
                    echo "テストコードの操作後、プロダクションコードを操作することは禁止しています" >&2
                    exit 2
                fi
                transcript_file_type="product"
            elif is_test_code "$transcript_file"; then
                if [ "$transcript_file_type" = "product" ]; then
                    # 混在している場合はエラー
                    echo "{\"hookSpecificOutput\": { \"hookEventName\": \"PreToolUse\", \"permissionDecision\": \"deny\", \"permissionDecisionReason\": \"プロダクションコードの操作後、テストコードを操作することは禁止しています\"}}" | jq -rc
                    echo "プロダクションコードの操作後、テストコードを操作することは禁止しています" >&2
                    exit 2
                fi
                transcript_file_type="test"
            fi
        done <<<"$transcript_file_paths"

        # 現在のfile_pathsとtranscript_file_typeの組み合わせをチェック
        if [ -n "$transcript_file_type" ]; then
            # ツール名を取得
            tool_name=$(echo "$json_input" | jq -r '.tool_name // ""')

            # ファイルパスを取得（ツールによって異なる場所にある）
            current_file_paths=""

            case "$tool_name" in
            "Read" | "Edit" | "Write" | "NotebookRead" | "NotebookEdit")
                # 単一ファイルパス
                current_file_paths=$(echo "$json_input" | jq -r '.tool_input.file_path // empty')
                ;;
            "MultiEdit")
                # MultiEditの場合は単一ファイルパス
                current_file_paths=$(echo "$json_input" | jq -r '.tool_input.file_path // empty')
                ;;
            "LS" | "Glob" | "Grep")
                # パスパラメータ
                current_file_paths=$(echo "$json_input" | jq -r '.tool_input.path // empty')
                ;;
            esac

            current_file_type=""
            while IFS= read -r current_file; do
                [ -z "$current_file" ] && continue

                if is_product_code "$current_file"; then
                    current_file_type="product"
                    break
                elif is_test_code "$current_file"; then
                    current_file_type="test"
                    break
                fi
            done <<<"$current_file_paths"

            # セッションタイプと現在の操作タイプの整合性チェック
            if [ -n "$current_file_type" ] && [ "$transcript_file_type" != "$current_file_type" ]; then
                if [ "$transcript_file_type" = "product" ] && [ "$current_file_type" = "test" ]; then
                    echo "{\"hookSpecificOutput\": { \"hookEventName\": \"PreToolUse\", \"permissionDecision\": \"deny\", \"permissionDecisionReason\": \"プロダクションコードを扱うセッションでテストコードの操作は禁止されています\"}}" | jq -rc
                    echo "プロダクションコードを扱うセッションでテストコードの操作は禁止されています" >&2
                    exit 2
                elif [ "$transcript_file_type" = "test" ] && [ "$current_file_type" = "product" ]; then
                    echo "{\"hookSpecificOutput\": { \"hookEventName\": \"PreToolUse\", \"permissionDecision\": \"deny\", \"permissionDecisionReason\": \"テストコードを扱うセッションでプロダクションコードの操作は禁止されています\"}}" | jq -rc
                    echo "テストコードを扱うセッションでプロダクションコードの操作は禁止されています" >&2
                    exit 2
                fi
            fi
        fi
    fi
fi

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
    if echo "$command" | grep -qE '(^|[;&|]).*[[:space:]]*(rm|mv|cp|cat|less|more|head|tail|chmod|chown)[[:space:]]+'; then
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

# 各ファイルパスをチェック
# whileループのサブシェル問題を避けるため、終了ステータスを変数で管理
exit_status=0

while IFS= read -r file_path; do
    # 空の行はスキップ
    [ -z "$file_path" ] && continue

    # 完全保護対象のチェック（すべての操作を禁止）
    if is_fully_protected "$file_path"; then
        # エラーメッセージをJSON形式で出力
        echo "{\"hookSpecificOutput\": { \"hookEventName\": \"PreToolUse\", \"permissionDecision\": \"deny\", \"permissionDecisionReason\": \"セキュリティポリシーにより、このファイルへのあらゆるアクセスが制限されています: $file_path\"}}" | jq -rc
        exit_status=2
        break
    fi

    # 書き込み保護対象のチェック（読み込みのみ許可）
    if is_write_protected "$file_path" && is_write_tool "$tool_name"; then
        # エラーメッセージをJSON形式で出力
        echo "{\"hookSpecificOutput\": { \"hookEventName\": \"PreToolUse\", \"permissionDecision\": \"deny\", \"permissionDecisionReason\": \"このファイルは読み込み専用です。更新や削除は許可されていません: $file_path\"}}" | jq -rc
        exit_status=2
        break
    fi
done <<<"$file_paths"

# 設定された終了ステータスで終了
exit $exit_status
