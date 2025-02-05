#!/bin/sh

# VSCodeの実行ファイルのパスを取得
EXEPATH=$(which.exe code.exe 2>/dev/null)

# EXEPATHが見つからない場合のエラーハンドリング
if [ -z "$EXEPATH" ]; then
  echo "Error: code.exe not found in PATH" >&2
  exit 1
fi

# VSCodeの実行パスを設定
CODEPATH="/mnt/c$(dirname "$EXEPATH" | cut -c 3-)/bin/code"

# VSCodeを実行
"$CODEPATH" "$@"
