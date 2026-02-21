FROM ghcr.io/phioranex/openclaw-docker:latest

USER root
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      python3 \
      python3-venv \
      python3-pip \
      python3-dev \
      build-essential \
      git \
      ca-certificates \
      curl \
      ffmpeg \
     #python3-whisper \
 && rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
      DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends xvfb && \
      mkdir -p /home/node/.cache/ms-playwright && \
      PLAYWRIGHT_BROWSERS_PATH=/home/node/.cache/ms-playwright \
      node /app/node_modules/playwright-core/cli.js install --with-deps chromium && \
      chown -R node:node /home/node/.cache/ms-playwright && \
      apt-get clean && \
      rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*;

# Some tooling expects `python`
RUN ln -sf /usr/bin/python3 /usr/local/bin/python

# BEGIN Install Homebrew: let you install skill via openclaw cli

# 1) Prepare install dir as root
USER root
RUN mkdir -p /home/linuxbrew/.linuxbrew \
 && chown -R node:node /home/linuxbrew

# 2) Install Homebrew as non-root user (node)
USER node
ENV NONINTERACTIVE=1
RUN /bin/bash -lc "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 3) Add Homebrew to PATH (for subsequent layers)
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"

# 4) Optional: allow node to manage brew dirs without permission hell
USER root
RUN groupadd -f homebrew \
 && usermod -aG homebrew node \
 && chown -R node:homebrew /home/linuxbrew/.linuxbrew \
 && chmod -R g+w /home/linuxbrew/.linuxbrew

USER node
# END Install Homebrew