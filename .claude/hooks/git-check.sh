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

# コマンドの内容を判定
if echo "$tool_input_command" | grep -qE 'git commit'; then
    echo '{ "hookSpecificOutput": { "hookEventName": "PreToolUse", "permissionDecision": "ask", "permissionDecisionReason": "git commitはユーザーに確認を求める必要があります" } }' | jq -rc
elif echo "$tool_input_command" | grep -qE 'git reset.*--hard'; then
    echo '{ "hookSpecificOutput": { "hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "git reset --hardは許可されていません" } }' | jq -rc
    exit 2
elif echo "$tool_input_command" | grep -qE 'git reset'; then
    echo '{ "hookSpecificOutput": { "hookEventName": "PreToolUse", "permissionDecision": "allow", "permissionDecisionReason": "git resetは許可されています" } }' | jq -rc
elif echo "$tool_input_command" | grep -qE 'git add'; then
    echo '{ "hookSpecificOutput": { "hookEventName": "PreToolUse", "permissionDecision": "allow", "permissionDecisionReason": "git addは許可されています" } }' | jq -rc
elif echo "$tool_input_command" | grep -qE 'git rm'; then
    echo '{ "hookSpecificOutput": { "hookEventName": "PreToolUse", "permissionDecision": "allow", "permissionDecisionReason": "git rmは許可されています" } }' | jq -rc
fi
