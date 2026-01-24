FROM debian:stable

ARG USERNAME
ARG CHEZMOI_DOTFILES_REPO
ARG USE_RUST=true
ARG USE_NPM=true
ARG USE_UV=true
ARG USE_CLAUDE_CODE=true
ARG USE_CODEX=true
ARG USE_MISE=false

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
    gcc \
    g++ \
    make \
    cmake \
    ninja-build \
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
    libicu-dev \
    liblzma-dev \
    libncurses-dev \
    libnghttp2-dev \
    libpq-dev \
    libreadline-dev \
    libsqlite3-dev \
    libssl-dev \
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

# Install uv
RUN if [ "${USE_UV}" = "true" ]; then \
        curl -LsSf https://astral.sh/uv/install.sh | sh; \
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

# Install mise
RUN if [ "${USE_MISE}" = "true" ]; then \
        curl https://mise.run | sh; \
    fi

# Install chezmoi and apply dotfiles (if CHEZMOI_DOTFILES_REPO is set)
RUN if [ -n "${CHEZMOI_DOTFILES_REPO}" ]; then \
        sh -c "$(curl -fsLS get.chezmoi.io)" \
        && bin/chezmoi init ${CHEZMOI_DOTFILES_REPO} \
        && bin/chezmoi apply; \
    fi

# Set default shell to zsh
SHELL ["/bin/zsh", "-c"]
ENV SHELL=/bin/zsh

CMD ["/bin/zsh"]
