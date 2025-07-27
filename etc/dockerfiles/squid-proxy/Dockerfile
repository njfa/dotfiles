FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y squid && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Squidの設定ディレクトリとログディレクトリの準備
RUN mkdir -p /etc/squid/conf.d /var/log/squid /var/spool/squid /var/run/squid && \
    chown -R proxy:proxy /var/log/squid /var/spool/squid /var/run/squid && \
    chmod 755 /var/log/squid /var/spool/squid /var/run/squid

# 設定ファイルをコピー
COPY squid.conf /etc/squid/squid.conf
COPY allowed-domains.txt /etc/squid/allowed-domains.txt

# Squidのキャッシュディレクトリを初期化（rootユーザーで実行）
RUN squid -N -z

EXPOSE 3128

# 起動スクリプトを作成
RUN echo '#!/bin/bash' > /usr/local/bin/start-squid.sh && \
    echo '# ログディレクトリとPIDファイルの権限を設定' >> /usr/local/bin/start-squid.sh && \
    echo 'mkdir -p /var/run/squid /var/log/squid' >> /usr/local/bin/start-squid.sh && \
    echo 'chown -R proxy:proxy /var/log/squid /var/spool/squid /var/run/squid' >> /usr/local/bin/start-squid.sh && \
    echo 'chmod 755 /var/log/squid /var/run/squid' >> /usr/local/bin/start-squid.sh && \
    echo '# ログファイルを作成' >> /usr/local/bin/start-squid.sh && \
    echo 'touch /var/log/squid/access.log /var/log/squid/cache.log /var/log/squid/store.log' >> /usr/local/bin/start-squid.sh && \
    echo 'chown proxy:proxy /var/log/squid/*.log' >> /usr/local/bin/start-squid.sh && \
    echo '# Squidをproxyユーザーで実行' >> /usr/local/bin/start-squid.sh && \
    echo 'exec su -s /bin/bash proxy -c "squid -N -d 1"' >> /usr/local/bin/start-squid.sh && \
    chmod +x /usr/local/bin/start-squid.sh

# Squidをフォアグラウンドで実行
CMD ["/usr/local/bin/start-squid.sh"]