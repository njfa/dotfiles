FROM node:20

ARG TZ
ARG PYTHON_VERSION
ARG UV_VERSION
ARG GIT_DELTA_VERSION

ENV TZ="$TZ"
ENV PYTHON_VERSION="${PYTHON_VERSION:-3.12}"
ENV GIT_DELTA_VERSION="${GIT_DELTA_VERSION:-0.18.2}"

# Install basic development tools and iptables/ipset
RUN apt update && apt install -y less \
  git \
  procps \
  sudo \
  fzf \
  zsh \
  man-db \
  unzip \
  gnupg2 \
  gh \
  iptables \
  ipset \
  iproute2 \
  dnsutils \
  aggregate \
  jq

# Ensure default node user has access to /usr/local/share
RUN mkdir -p /usr/local/share/npm-global && \
    chown -R node:node /usr/local/share

ARG USERNAME=node

# Persist bash history.
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
  && mkdir /commandhistory \
  && touch /commandhistory/.bash_history \
  && chown -R $USERNAME /commandhistory

# Set `DEVCONTAINER` environment variable to help with orientation
ENV DEVCONTAINER=true

# Create workspace and config directories and set permissions
RUN mkdir -p /workspace /home/node/.claude && \
  chown -R node:node /workspace /home/node/.claude

WORKDIR /workspace

RUN ARCH=$(dpkg --print-architecture) && \
  wget "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  sudo dpkg -i "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  rm "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb"

# Install pyenv dependencies
RUN apt-get update && \
    apt-get install -y \
    make build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

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

RUN npm config set prefix /usr/local/share/npm-global

# Install Claude
RUN npm install -g @anthropic-ai/claude-code

# Install pyenv
RUN curl -fsSL https://pyenv.run | bash && \
    eval "$(pyenv init -)" && \
    pyenv install ${PYTHON_VERSION} && \
    pyenv global ${PYTHON_VERSION} && \
    pip install --upgrade pip && \
    pip install uv

# Copy and set up firewall script
COPY init-firewall.sh /usr/local/bin/


USER root
RUN chmod +x /usr/local/bin/init-firewall.sh && \
  echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/node-firewall && \
  chmod 0440 /etc/sudoers.d/node-firewall

# Create a custom entrypoint script with all environment initialization
RUN echo '#!/bin/bash' > /usr/local/bin/entrypoint.sh && \
    echo 'export PYENV_ROOT="/usr/local/share/pyenv"' >> /usr/local/bin/entrypoint.sh && \
    echo 'export PATH="$PYENV_ROOT/bin:/usr/local/share/npm-global/bin:$PATH"' >> /usr/local/bin/entrypoint.sh && \
    echo 'eval "$(pyenv init -)"' >> /usr/local/bin/entrypoint.sh && \
    echo 'exec "$@"' >> /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh

USER node

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["claude"]
