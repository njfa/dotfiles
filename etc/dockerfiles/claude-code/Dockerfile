# ========================================
# ビルドステージ: Python環境の構築
# ========================================
FROM node:20 AS python-builder

ARG PYTHON_VERSION
ENV PYTHON_VERSION="${PYTHON_VERSION:-3.10}"
ENV PYENV_ROOT=/usr/local/share/pyenv

# Pythonビルドに必要な依存関係のみインストール
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    ca-certificates \
    libssl-dev libbz2-dev libreadline-dev libsqlite3-dev \
    libncursesw5-dev llvm libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev \
    tk-dev \
    xz-utils \
    zlib1g-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# pyenvをインストールしてPythonをビルド
RUN curl -fsSL https://pyenv.run | bash && \
    export PATH="$PYENV_ROOT/bin:$PATH" && \
    eval "$(pyenv init -)" && \
    pyenv install ${PYTHON_VERSION} && \
    pyenv global ${PYTHON_VERSION} && \
    # Python実行環境のみを残す
    find $PYENV_ROOT -type f -name "*.pyc" -delete && \
    find $PYENV_ROOT -type d -name "__pycache__" -delete && \
    rm -rf $PYENV_ROOT/sources

# ========================================
# ビルドステージ: git-delta、neovimのダウンロード
# ========================================
FROM node:20-slim AS downloader

ARG GIT_DELTA_VERSION
ENV GIT_DELTA_VERSION="${GIT_DELTA_VERSION:-0.18.2}"

# git-deltaのダウンロード
RUN apt-get update && \
    apt-get install -y --no-install-recommends wget ca-certificates && \
    ARCH=$(dpkg --print-architecture) && \
    wget "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" -O /tmp/git-delta.deb

# neovimのダウンロードと展開
RUN arch=$(uname -m) && \
    case "$arch" in \
        x86_64) \
            arch_suffix="linux-x86_64" \
            ;; \
        aarch64|arm64) \
            arch_suffix="linux-arm64" \
            ;; \
        *) \
            echo "Unsupported architecture: $arch" \
            exit 1 \
            ;; \
    esac && \
    if ! wget "https://github.com/neovim/neovim/releases/latest/download/nvim-${arch_suffix}.appimage" -O /tmp/nvim.appimage; then \
        echo "Failed to download nvim-${arch_suffix}.appimage, trying legacy filename..." && \
        wget "https://github.com/neovim/neovim/releases/latest/download/nvim.appimage" -O /tmp/nvim.appimage; \
    fi && \
    chmod u+x /tmp/nvim.appimage && \
    /tmp/nvim.appimage --appimage-extract && \
    mv squashfs-root /tmp/squashfs-root

# ========================================
# 最終ステージ: 実行環境
# ========================================
FROM node:20-slim

ARG TZ
ARG UV_VERSION
ARG USERNAME=node

ENV TZ="$TZ"
ENV DEVCONTAINER=true
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PYENV_ROOT=/usr/local/share/pyenv
ENV PATH=$PYENV_ROOT/bin:$PATH:/usr/local/share/npm-global/bin
ENV SHELL="/bin/zsh"
ENV EDITOR="nvim"

# Copy and set up firewall script
COPY init-firewall.sh /usr/local/bin/

WORKDIR /workspace

# 実行時に必要な最小限のパッケージのみインストール
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    dnsutils \
    fzf \
    gh git gnupg2 \
    iptables ipset iproute2 \
    jq \
    less \
    procps \
    sudo \
    unzip \
    wget \
    zsh \
    # Python実行に必要な最小限のライブラリ
    libssl3 libsqlite3-0 libbz2-1.0 libreadline8 libncursesw6 \
    libffi8 liblzma5 tk && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    # ディレクトリの作成と権限設定
    mkdir -p /usr/local/share/npm-global /workspace /home/node/.claude /commandhistory && \
    touch /commandhistory/.bash_history && \
    chown -R node:node /usr/local/share /workspace /home/node/.claude /commandhistory && \
    # firewall設定
    chmod +x /usr/local/bin/init-firewall.sh && \
    echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/node-firewall && \
    chmod 0440 /etc/sudoers.d/node-firewall

# git-deltaをインストール
COPY --from=downloader /tmp/git-delta.deb /tmp/
RUN dpkg -i /tmp/git-delta.deb && rm /tmp/git-delta.deb

# neovimをコピー
COPY --from=downloader /tmp/squashfs-root /usr/local/nvim

# vimコマンドのシンボリックリンクを作成
RUN ln -s /usr/local/nvim/usr/bin/nvim /usr/local/bin/vim && \
    ln -s /usr/local/nvim/usr/bin/nvim /usr/local/bin/nvim

# ビルド済みのPython環境をコピー
COPY --from=python-builder --chown=node:node $PYENV_ROOT $PYENV_ROOT

# entrypointスクリプトの作成
RUN echo '#!/bin/bash' > /usr/local/bin/entrypoint.sh && \
    echo 'export PYENV_ROOT="/usr/local/share/pyenv"' >> /usr/local/bin/entrypoint.sh && \
    echo 'export PATH="$PYENV_ROOT/bin:/usr/local/share/npm-global/bin:$PATH"' >> /usr/local/bin/entrypoint.sh && \
    echo 'eval "$(pyenv init -)"' >> /usr/local/bin/entrypoint.sh && \
    echo 'exec "$@"' >> /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh

# Set up non-root user
USER node

# zshとヒストリー設定
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.2.0/zsh-in-docker.sh)" -- \
    -p git \
    -p fzf \
    -a "source /usr/share/doc/fzf/examples/key-bindings.zsh" \
    -a "source /usr/share/doc/fzf/examples/completion.zsh" \
    -a "export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
    -x

# npmパッケージとPythonパッケージのインストール
RUN npm config set prefix /usr/local/share/npm-global && \
    npm install -g @anthropic-ai/claude-code && \
    npm cache clean --force && \
    export PATH="$PYENV_ROOT/bin:$PATH" && \
    eval "$(pyenv init -)" && \
    pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir uv yq

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["claude"]
