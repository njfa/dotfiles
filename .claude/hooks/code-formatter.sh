#!/bin/bash

# Claude Code hooks script for automatic code formatting
# This script is triggered after file edits to apply appropriate formatters

# Read the JSON input from stdin
json_input=$(cat)

# Extract file paths from the JSON input
# Handle both single file_path and multiple file_paths array
file_paths=$(echo "$json_input" | jq -r '
if .tool_input.file_path then
    .tool_input.file_path
elif .tool_input.file_paths then
    .tool_input.file_paths[]
else
    empty
end
')

# Exit if no file paths are found
if [ -z "$file_paths" ]; then
    exit 0
fi

# Process each file path
echo "$file_paths" | while IFS= read -r file_path; do
    # Skip empty lines
    [ -z "$file_path" ] && continue

    # Format JavaScript/TypeScript files with prettier
    if echo "$file_path" | grep -qE '\.(js|ts|jsx|tsx)$'; then
        if command -v prettier >/dev/null 2>&1; then
            prettier --write "$file_path" 2>/dev/null || true
        fi
    fi

    # Format Python files with black
    if echo "$file_path" | grep -qE '\.py$'; then
        if command -v black >/dev/null 2>&1; then
            black "$file_path" 2>/dev/null || true
        fi
    fi

    # Format Bash/Shell files with shfmt
    if echo "$file_path" | grep -qE '\.(sh|bash)$'; then
        if command -v shfmt >/dev/null 2>&1; then
            shfmt -i 4 -w "$file_path" 2>/dev/null || true
        fi
    fi

    # Format Java files with google-java-format
    if echo "$file_path" | grep -qE '\.java$'; then
        if command -v google-java-format >/dev/null 2>&1; then
            google-java-format --replace "$file_path" 2>/dev/null || true
        fi
    fi
done

# Exit successfully
exit 0
