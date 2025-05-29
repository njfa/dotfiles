FROM node:20

ARG TZ
ARG PYTHON_VERSION
ARG UV_VERSION
ARG GIT_DELTA_VERSION
ARG ADDITIONAL_CA_CERT_PATH
ARG USERNAME=node

ENV TZ="$TZ"
ENV PYTHON_VERSION="${PYTHON_VERSION:-3.12}"
ENV GIT_DELTA_VERSION="${GIT_DELTA_VERSION:-0.18.2}"
# Set `DEVCONTAINER` environment variable to help with orientation
ENV DEVCONTAINER=true

# カスタムCA証明書の追加（指定された場合）
# デフォルトは同じディレクトリ内の.emptyファイルを使用
COPY ${ADDITIONAL_CA_CERT_PATH:-.empty} /tmp/additional-ca-cert.crt

# Copy and set up firewall script
COPY init-firewall.sh /usr/local/bin/

WORKDIR /workspace

# Install basic development tools and iptables/ipset, pyenv dependencies
RUN apt update && \
    apt install -y --no-install-recommends \
    aggregate \
    build-essential \
    curl \
    dnsutils \
    fzf \
    gh git gnupg2 \
    iptables ipset iproute2 \
    jq \
    less libssl-dev libbz2-dev libreadline-dev libsqlite3-dev \
    libncursesw5-dev llvm libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev \
    make man-db \
    procps \
    sudo \
    tk-dev \
    unzip \
    xz-utils \
    zlib1g-dev zsh \
    wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    # 証明書のインストール
    if [ -s /tmp/additional-ca-cert.crt ] && [ -f /tmp/additional-ca-cert.crt ] && [ "$(head -c 1 /tmp/additional-ca-cert.crt | wc -c)" -gt 0 ] && ! grep -q "^# This is an empty placeholder" /tmp/additional-ca-cert.crt; then \
        cp /tmp/additional-ca-cert.crt /usr/local/share/ca-certificates/ && \
        update-ca-certificates && \

        # Node.js用の環境変数設定
        export NODE_EXTRA_CA_CERTS=/usr/local/share/ca-certificates/additional-ca-cert.crt && \
        # npmの証明書設定
        npm config set cafile /usr/local/share/ca-certificates/additional-ca-cert.crt; \
    fi && \
    rm -f /tmp/additional-ca-cert.crt && \
    # node用のディレクトリを作成
    mkdir -p /usr/local/share/npm-global /workspace /home/node/.claude && \
    chown -R node:node /usr/local/share /workspace /home/node/.claude && \
    # Persist bash history.
    SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" && \
    mkdir /commandhistory && \
    touch /commandhistory/.bash_history && \
    chown -R $USERNAME /commandhistory && \
    # git-delta
    ARCH=$(dpkg --print-architecture) && \
    wget "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
    sudo dpkg -i "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
    rm "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
    # firewall
    chmod +x /usr/local/bin/init-firewall.sh && \
    echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/node-firewall && \
    chmod 0440 /etc/sudoers.d/node-firewall && \
    # Create a custom entrypoint script with all environment initialization
    echo '#!/bin/bash' > /usr/local/bin/entrypoint.sh && \
    echo 'export PYENV_ROOT="/usr/local/share/pyenv"' >> /usr/local/bin/entrypoint.sh && \
    echo 'export PATH="$PYENV_ROOT/bin:/usr/local/share/npm-global/bin:$PATH"' >> /usr/local/bin/entrypoint.sh && \
    echo 'eval "$(pyenv init -)"' >> /usr/local/bin/entrypoint.sh && \
    echo 'exec "$@"' >> /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh


# Set up non-root user
USER node

# Install global packages
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PYENV_ROOT=/usr/local/share/pyenv
ENV PATH=$PYENV_ROOT/bin:$PATH:/usr/local/share/npm-global/bin

# Set the default shell to bash rather than sh
ENV SHELL="/bin/zsh"

# Default powerline10k theme
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.2.0/zsh-in-docker.sh)" -- \
  -p git \
  -p fzf \
  -a "source /usr/share/doc/fzf/examples/key-bindings.zsh" \
  -a "source /usr/share/doc/fzf/examples/completion.zsh" \
  -a "export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
  -x

RUN npm config set prefix /usr/local/share/npm-global && \
    npm install -g @anthropic-ai/claude-code && \
    npm cache clean --force

# Install pyenv
RUN curl -fsSL https://pyenv.run | bash && \
    eval "$(pyenv init -)" && \
    pyenv install ${PYTHON_VERSION} && \
    pyenv global ${PYTHON_VERSION} && \
    pip install --upgrade pip && \
    pip install uv && \
    pip install yq

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["claude"]
