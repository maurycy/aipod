FROM debian:stable

ARG USERNAME
ARG CHEZMOI_DOTFILES_REPO

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
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Install Rust and Cargo
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Install ripgrep via cargo
RUN $HOME/.cargo/bin/cargo install ripgrep

# Install nvm and Node.js
RUN export HOME=/home/${USERNAME} NVM_DIR="$HOME/.nvm" \
    && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash \
    && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" \
    && nvm install 25

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
