FROM debian:stable

ARG USERNAME
ARG CHEZMOI_DOTFILES_REPO
ARG USE_RUST=true
ARG USE_NPM=true
ARG USE_UV=true
ARG UV_DEFAULT_PYTHON_VERSION=3.14
ARG USE_CLAUDE_CODE=true
ARG USE_CODEX=true
ARG USE_COPILOT=true
ARG USE_PI=true
ARG USE_AGY=true
ARG USE_MISE=false
ARG USE_OVERMIND=false
ARG USE_JUST=false
ARG USE_BUN=false

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
    # Base system
    base-files \
    base-passwd \
    coreutils \
    util-linux \
    debianutils \
    bash \
    bash-completion \
    dash \
    zsh \
    login \
    passwd \
    sudo \
    locales \
    locales-all \
    tzdata \
    ca-certificates \
    # Package management
    apt \
    apt-utils \
    apt-file \
    dpkg \
    debian-archive-keyring \
    gnupg \
    gpgv \
    # Build toolchain
    build-essential \
    clang \
    lld \
    llvm \
    libclang-rt-dev \
    gcc \
    g++ \
    make \
    cmake \
    ninja-build \
    pkg-config \
    bison \
    flex \
    ccache \
    sccache \
    fakeroot \
    dh-autoreconf \
    autotools-dev \
    # Version control
    git \
    git-lfs \
    gh \
    # Editors and text processing
    vim \
    sed \
    grep \
    diffutils \
    mawk \
    less \
    man-db \
    manpages \
    # Compression
    gzip \
    bzip2 \
    xz-utils \
    lz4 \
    zstd \
    unzip \
    tar \
    pigz \
    pbzip2 \
    # Networking
    curl \
    wget \
    openssh-client \
    mosh \
    iproute2 \
    iputils-ping \
    net-tools \
    netbase \
    netcat-traditional \
    socat \
    # Development libraries
    libbz2-dev \
    libffi-dev \
    libgdbm-dev \
    libicu-dev \
    liblzma-dev \
    libncurses-dev \
    libnghttp2-dev \
    libpq-dev \
    libreadline-dev \
    libsqlite3-dev \
    libssl-dev \
    tk-dev \
    uuid-dev \
    libudev-dev \
    libyaml-dev \
    libelf-dev \
    zlib1g-dev \
    libusb-dev \
    # Languages and tools
    perl \
    protobuf-compiler \
    jq \
    sqlite3 \
    # Debugging and profiling
    gdb \
    strace \
    valgrind \
    htop \
    procps \
    pv \
    # Terminal multiplexers
    tmux \
    screen \
    # Misc utilities
    file \
    findutils \
    tree \
    rsync \
    time \
    bc \
    hostname \
    lsof \
    fastfetch \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create user with sudo access
RUN useradd -m -s /bin/zsh ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Update apt-file cache
RUN apt-file update || true

# Switch to user
USER ${USERNAME}
WORKDIR /home/${USERNAME}

# Install uv - and, when UV_DEFAULT_PYTHON_VERSION is set, pre-install it as the default
# interpreter so `uv run`/`uv venv` need no download at container runtime
RUN if [ "${USE_UV}" = "true" ]; then \
        curl -LsSf https://astral.sh/uv/install.sh | sh \
        && if [ -n "${UV_DEFAULT_PYTHON_VERSION}" ]; then \
               $HOME/.local/bin/uv python install "${UV_DEFAULT_PYTHON_VERSION}" --default; \
           fi; \
    fi

# Install Rust and Cargo
RUN if [ "${USE_RUST}" = "true" ]; then \
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
        && $HOME/.cargo/bin/cargo install ripgrep; \
    fi

# Install nvm and Node.js
RUN if [ "${USE_NPM}" = "true" ]; then \
        export HOME=/home/${USERNAME} NVM_DIR="$HOME/.nvm" \
        && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash \
        && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" \
        && nvm install 25; \
    fi

# Install Claude Code
RUN if [ "${USE_CLAUDE_CODE}" = "true" ]; then \
        curl -fsSL https://claude.ai/install.sh | bash; \
    fi

# Install OpenAI Codex (requires npm)
RUN if [ "${USE_CODEX}" = "true" ] && [ "${USE_NPM}" = "true" ]; then \
        export HOME=/home/${USERNAME} NVM_DIR="$HOME/.nvm" \
        && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" \
        && npm i -g @openai/codex; \
    fi

# Install GitHub Copilot CLI (requires npm)
RUN if [ "${USE_COPILOT}" = "true" ] && [ "${USE_NPM}" = "true" ]; then \
        export HOME=/home/${USERNAME} NVM_DIR="$HOME/.nvm" \
        && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" \
        && npm i -g @github/copilot; \
    fi

# Install Pi coding agent (requires npm)
RUN if [ "${USE_PI}" = "true" ] && [ "${USE_NPM}" = "true" ]; then \
        export HOME=/home/${USERNAME} NVM_DIR="$HOME/.nvm" \
        && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" \
        && npm i -g @earendil-works/pi-coding-agent; \
    fi

# Install Antigravity CLI - no npm needed; installer drops the agy binary into ~/.local/bin
RUN if [ "${USE_AGY}" = "true" ]; then \
        export HOME=/home/${USERNAME} \
        && curl -fsSL https://antigravity.google/cli/install.sh | bash; \
    fi

# Install mise
RUN if [ "${USE_MISE}" = "true" ]; then \
        curl https://mise.run | sh; \
    fi

# Install overmind
RUN if [ "${USE_OVERMIND}" = "true" ]; then \
        curl -fsSL https://github.com/DarthSim/overmind/releases/download/v2.5.1/overmind-v2.5.1-linux-arm64.gz | gunzip > ~/.local/bin/overmind \
        && chmod +x ~/.local/bin/overmind; \
    fi

# Install just
RUN if [ "${USE_JUST}" = "true" ]; then \
        curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to ~/.local/bin; \
    fi

# Install Bun - no npm needed; BUN_INSTALL=~/.local lands the binary on PATH alongside uv
RUN if [ "${USE_BUN}" = "true" ]; then \
        export HOME=/home/${USERNAME} BUN_INSTALL="/home/${USERNAME}/.local" \
        && curl -fsSL https://bun.sh/install | bash; \
    fi

# Install chezmoi and apply dotfiles (if CHEZMOI_DOTFILES_REPO is set)
RUN if [ -n "${CHEZMOI_DOTFILES_REPO}" ]; then \
        sh -c "$(curl -fsLS get.chezmoi.io/lb)" \
        && .local/bin/chezmoi init ${CHEZMOI_DOTFILES_REPO} \
        && .local/bin/chezmoi apply; \
    fi

# Set default shell to zsh
ENV SHELL=/bin/zsh

CMD ["/bin/zsh"]
