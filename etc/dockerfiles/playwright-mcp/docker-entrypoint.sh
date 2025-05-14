#!/bin/bash

# クワイエットモードフラグ（デフォルトは false）
QUIET_MODE=false
NODE_ARGS=()

# 引数の処理
# -q オプションを取り除き、他の引数は NODE_ARGS に追加
for arg in "$@"; do
    if [ "$arg" = "-q" ]; then
        QUIET_MODE=true
    else
        NODE_ARGS+=("$arg")
    fi
done

# 引数がない場合（-q だけの場合も含む）はデフォルトオプションで実行
if [ ${#NODE_ARGS[@]} -eq 0 ]; then
    if [ "$QUIET_MODE" = false ]; then
        echo "======================================================"
        echo "Playwright MCP コンテナ"
        echo "======================================================"
        echo ""
        echo "注: このメッセージを非表示にするには -q オプションを指定してください"
        echo ""
        echo "使用方法: docker run [DOCKER_OPTIONS] playwright-mcp [OPTIONS]"
        echo ""
        echo "例:"
        echo "  コンテナのヘルプを表示:"
        echo "    docker run playwright-mcp --help"
        echo ""
        echo "  特定のブラウザでヘッドレスモードで実行:"
        echo "    docker run -p 8139:8139 playwright-mcp --headless --browser chrome --port 8139"
        echo "    (--port: SSE transportのリッスンポート)"
        echo ""
        echo "  特定のブラウザとデバイスを指定:"
        echo "    docker run playwright-mcp --headless --browser chrome --device \"iPhone 15\""
        echo ""
        echo "  メッセージを非表示にして実行:"
        echo "    docker run playwright-mcp -q [OPTIONS]"
        echo ""
        echo "利用可能なオプションの詳細については '--help' オプションを指定してください"
        echo "======================================================"
        echo ""
        echo "引数が指定されていないため、デフォルト設定で起動します: --headless --browser chrome --port 8931"
        echo ""
    fi

    # デフォルトオプションで実行
    exec node /app/cli.js --headless --browser chrome --port 8931
else
    # 引数がある場合は通常通り実行（-q は除外済み）
    exec node /app/cli.js "${NODE_ARGS[@]}"
fi