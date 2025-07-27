#!/bin/bash

# 環境変数操作を検出して拒否するスクリプト

json_input=$(cat)

tool_input_command=$(echo "$json_input" | jq -r '
if .tool_input.command then
    .tool_input.command
else
    empty
end')

if [ -z "$tool_input_command" ]; then
    exit 0
fi

# Track if any formatter failed
has_error=0
result=""

# Output a blank line at the start of stderr
echo >&2

# コマンドの内容を判定
if echo "$tool_input_command" | grep -qE '\b(export|unset|env|printenv|set)\b|\$[A-Z_][A-Z0-9_]*|\$\{[A-Z_][A-Z0-9_]*\}|^\$\{?[A-Z_][A-Z0-9_]*\}?\s*=|^[A-Z_][A-Z0-9_]*='; then
    result='{"decision": "block", "reason": "環境変数の操作は許可されていません。別の方法を検討してください。"}'
elif echo "$tool_input_command" | grep -qE 'rm -rf|dd if=|:\(\){ :\|:& \};:'; then
    result='{"decision": "block", "reason": "危険なコマンドは実行できません。別の方法を検討してください。"}'
fi

if [ -n "$result" ]; then
    echo "$result"
    exit 2
fi
