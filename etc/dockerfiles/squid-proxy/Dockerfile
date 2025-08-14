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
COPY squid.conf.template /etc/squid/squid.conf.template
COPY domains-get-only.txt /etc/squid/domains-get-only.txt
COPY domains-connect-only.txt /etc/squid/domains-connect-only.txt
COPY domains-no-unsafe.txt /etc/squid/domains-no-unsafe.txt
COPY domains-all-methods.txt /etc/squid/domains-all-methods.txt

EXPOSE 3128

# 起動スクリプトを作成
COPY start-squid.sh /usr/local/bin/start-squid.sh
RUN chmod +x /usr/local/bin/start-squid.sh

# Squidをフォアグラウンドで実行
CMD ["/usr/local/bin/start-squid.sh"]
