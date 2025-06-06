ARG VARIANT="5.10"
FROM swift:${VARIANT}-jammy

# Install necessary dependencies
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
        git \
        curl \
        wget \
        unzip \
        libgd3 \
        libpng16-16 \
        libxkbcommon0 \
        libxkbcommon-x11-0 \
        build-essential \
        ca-certificates \
        gnupg \
        lsb-release \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Create non-root user
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Set up Swift environment
RUN echo "export PATH=/usr/bin:$PATH" >> /home/$USERNAME/.bashrc \
    && echo "export LANG=en_US.UTF-8" >> /home/$USERNAME/.bashrc

# Install SwiftLint
RUN git clone https://github.com/realm/SwiftLint.git /tmp/SwiftLint \
    && cd /tmp/SwiftLint \
    && swift build -c release \
    && mv .build/release/swiftlint /usr/local/bin/ \
    && cd / \
    && rm -rf /tmp/SwiftLint

# Install swift-format
RUN git clone https://github.com/apple/swift-format.git /tmp/swift-format \
    && cd /tmp/swift-format \
    && swift build -c release \
    && mv .build/release/swift-format /usr/local/bin/ \
    && cd / \
    && rm -rf /tmp/swift-format

# Install useful development tools
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
        vim \
        nano \
        tree \
        htop \
        jq \
        shellcheck \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Switch to non-root user
USER $USERNAME

# Create workspace directory
RUN mkdir -p /home/$USERNAME/workspace

# Set default working directory
WORKDIR /home/$USERNAME/workspace