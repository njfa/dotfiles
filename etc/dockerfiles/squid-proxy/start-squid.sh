#!/bin/bash
set -e

# ログディレクトリとPIDファイルの権限を設定
mkdir -p /var/run/squid /var/log/squid
chown -R proxy:proxy /var/log/squid /var/spool/squid /var/run/squid
chmod 755 /var/log/squid /var/run/squid

# ログファイルを作成
touch /var/log/squid/access.log /var/log/squid/cache.log /var/log/squid/store.log
chown proxy:proxy /var/log/squid/*.log

# # 設定ファイルをテンプレートから生成
cp /etc/squid/squid.conf.template /etc/squid/squid.conf

# 上位プロキシ設定（環境変数による動的設定）
if [ -n "$UPSTREAM_PROXY" ]; then
    echo "上位プロキシを設定中: $UPSTREAM_PROXY"

    # 上位プロキシの設定を生成
    UPSTREAM_CONFIG="# 上位プロキシ設定
cache_peer ${UPSTREAM_PROXY%:*} parent ${UPSTREAM_PROXY#*:} 0 no-query default
never_direct allow all
always_direct allow to_localnet"

    # テンプレートのプレースホルダーを上位プロキシ設定に置換
    sed -i "s|__UPSTREAM_PROXY_CONFIG__|${UPSTREAM_CONFIG}|" /etc/squid/squid.conf
else
    echo "上位プロキシは設定されていません（直接接続）"

    # プレースホルダーを削除（直接接続）
    sed -i "s|__UPSTREAM_PROXY_CONFIG__|# 直接接続（上位プロキシなし）|" /etc/squid/squid.conf
fi

# 設定ファイルの構文チェック
echo "設定ファイルの構文チェック中..."
squid -k parse

squid -N -z

# Squidをproxyユーザーで実行
echo "Squidを開始しています..."
exec su -s /bin/bash proxy -c "squid -N -d 1"
