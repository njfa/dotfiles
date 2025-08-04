
# ========================================
# ビルドステージ: git-delta、neovim、google-java-formatのダウンロード
# ========================================
FROM node:20-slim AS downloader

ARG GIT_DELTA_VERSION
ARG GOOGLE_JAVA_FORMAT_VERSION
ENV GIT_DELTA_VERSION="${GIT_DELTA_VERSION:-0.18.2}"
ENV GOOGLE_JAVA_FORMAT_VERSION="${GOOGLE_JAVA_FORMAT_VERSION:-1.19.2}"

# git-deltaのダウンロード
RUN apt-get update && \
    apt-get install -y --no-install-recommends wget ca-certificates && \
    ARCH=$(dpkg --print-architecture) && \
    wget "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" -O /tmp/git-delta.deb

# google-java-formatのダウンロード
RUN wget "https://github.com/google/google-java-format/releases/download/v${GOOGLE_JAVA_FORMAT_VERSION}/google-java-format-${GOOGLE_JAVA_FORMAT_VERSION}-all-deps.jar" -O /tmp/google-java-format.jar

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
FROM node:20

ARG TZ
ARG UV_VERSION
ARG PYTHON_VERSION
ARG USERNAME=node

ENV TZ="$TZ"
ENV DEVCONTAINER=true
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PYTHON_VERSION="${PYTHON_VERSION:-3.13}"
ENV UV_CACHE_DIR=/usr/local/share/uv-cache
ENV PATH=/usr/local/share/npm-global/bin:/usr/local/share/python-env/bin:/root/.local/bin:$PATH
ENV SHELL="/bin/zsh"
ENV EDITOR="nvim"

WORKDIR /workspace

# 実行時に必要な最小限のパッケージのみインストール
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    dnsutils \
    fzf \
    gh git gnupg2 \
    jq \
    less \
    procps \
    sudo \
    unzip \
    wget \
    zsh \
    # sh用のフォーマッター
    shfmt \
    # google-java-format用にJavaランタイムを追加
    openjdk-17-jre-headless && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    # ディレクトリの作成と権限設定
    mkdir -p /usr/local/share/npm-global /workspace /home/node/.claude /commandhistory /usr/local/share/uv-cache /usr/local/share/python-env && \
    touch /commandhistory/.bash_history && \
    chown -R node:node /usr/local/share /workspace /home/node/.claude /commandhistory

# git-deltaをインストール
COPY --from=downloader /tmp/git-delta.deb /tmp/
RUN dpkg -i /tmp/git-delta.deb && rm /tmp/git-delta.deb

# neovimをコピー
COPY --from=downloader /tmp/squashfs-root /usr/local/nvim

# vimコマンドのシンボリックリンクを作成
RUN ln -s /usr/local/nvim/usr/bin/nvim /usr/local/bin/vim && \
    ln -s /usr/local/nvim/usr/bin/nvim /usr/local/bin/nvim

# google-java-formatをコピーしてラッパースクリプトを作成
COPY --from=downloader /tmp/google-java-format.jar /usr/local/bin/google-java-format.jar
RUN echo '#!/bin/bash' > /usr/local/bin/google-java-format && \
    echo 'java -jar /usr/local/bin/google-java-format.jar "$@"' >> /usr/local/bin/google-java-format && \
    chmod +x /usr/local/bin/google-java-format

# uvをインストール
RUN curl -LsSf https://astral.sh/uv/install.sh | sh && \
    mv /root/.local/bin/uv /usr/local/bin/uv

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
    npm install -g @anthropic-ai/claude-code prettier markdownlint-cli && \
    npm cache clean --force && \
    uv python install ${PYTHON_VERSION} && \
    uv venv --system-site-packages /usr/local/share/python-env && \
    uv pip install --python /usr/local/share/python-env pip yq black numpy pandas aiohttp aiosqlite cryptography pytest pytest-asyncio pytest-cov structlog psutil

RUN git clone https://github.com/oraios/serena /usr/local/share/serena

CMD ["claude"]
