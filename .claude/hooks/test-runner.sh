#!/bin/bash

# Claude Code用テスト実行フック
# テストコード編集時に自動的にテストを実行する

# テストコードかチェックする関数（file-protection.shから拝借）
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

# Pythonテストファイルかチェックする関数
is_python_test() {
    local file_path="$1"
    echo "$file_path" | grep -qE '\.py$'
}

# Pythonテストコマンドを検出する関数（特定のファイルのみ実行）
get_python_test_command() {
    local project_root="$1"
    local test_file="$2" # 編集されたテストファイル

    # pytestがインストールされているかチェック
    if command -v pytest >/dev/null 2>&1; then
        # 特定のテストファイルのみを実行
        echo "pytest \"$test_file\" -v --tb=short"
        return 0
    fi

    # python -m unittestを試行
    if python3 -c "import unittest" >/dev/null 2>&1; then
        # ファイルパスをモジュール形式に変換
        local module_path="${test_file#$project_root/}"
        module_path="${module_path%.py}"
        module_path="${module_path//\//.}"
        echo "python3 -m unittest $module_path -v"
        return 0
    fi

    return 1
}

# プロジェクトルートを検出する関数
find_project_root() {
    local current_dir="$(pwd)"

    # Gitルートを検索
    while [ "$current_dir" != "/" ]; do
        if [ -d "$current_dir/.git" ]; then
            echo "$current_dir"
            return 0
        fi
        current_dir=$(dirname "$current_dir")
    done

    # Gitが見つからない場合は現在のディレクトリを返す
    echo "$(pwd)"
}

# 標準入力からJSONを読み込む
json_input=$(cat)

# ツール名を取得
tool_name=$(echo "$json_input" | jq -r '.tool_name // ""')

exit_status=0

# 書き込み系ツールのみを対象とする
case "$tool_name" in
Edit | MultiEdit | Write | NotebookEdit | mcp__serena*)
    # ファイルパスを取得
    file_path=""
    case "$tool_name" in
    Edit | MultiEdit | Write | NotebookEdit)
        file_path=$(echo "$json_input" | jq -r '.tool_input.file_path // empty')
        ;;
    mcp__serena*)
        file_path=$(echo "$json_input" | jq -r '.tool_input.relative_path // empty')
        ;;
    esac

    # ファイルパスが空の場合は終了
    [ -z "$file_path" ] && exit 0

    # テストコードかチェック
    if is_test_code "$file_path"; then
        # プロジェクトルートを検出
        project_root=$(find_project_root)
        test_command=""
        # タイムアウト設定（デフォルト30秒）
        TIMEOUT=${TEST_TIMEOUT:-30}

        # Pythonテストファイルかチェック
        if is_python_test "$file_path"; then
            # Pythonテストコマンドを取得（編集されたファイルのみ）
            test_command=$(get_python_test_command "$project_root" "$file_path")
        fi

        if [ -n "$test_command" ]; then
            # テストを実行（タイムアウト付き、failed/errorのみ表示）
            cd "$project_root"
            test_output=$(timeout "$TIMEOUT" bash -c "$test_command" 2>&1)
            test_exit_code=$?

            # failedとerrorの情報のみをフィルタリング
            filtered_output=$(echo "$test_output" | grep -iE "(failed|error|fail)")
            echo "$filtered_output" >&2

            if [ $test_exit_code -eq 124 ]; then
                echo "テスト ($test_command) がタイムアウトしました（${TIMEOUT}秒）。テストコードに問題がないか見直してください。" >&2
            elif [ $test_exit_code -eq 0 ]; then
                echo "テスト ($test_command) が成功しました。" >&2
            else
                echo "テスト ($test_command) が異常終了しました。テストコードに問題がないか見直してください。問題ないと判断した場合、起きている事象と問題ないと考える理由をユーザーに伝え、どうすべきか指示を求めてください。" >&2
            fi
            exit_status=2
        else
            echo "テストコマンドが取得できませんでした" >&2
        fi
    fi
    ;;
esac

exit $exit_status
