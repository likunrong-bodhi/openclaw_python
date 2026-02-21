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
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# Add Homebrew to the PATH
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"
# create group homebrew and add user node to it
RUN groupadd homebrew && usermod -aG homebrew node
# change group of /home/linuxbrew/.linuxbrew to homebrew
RUN chown -R root:homebrew /home/linuxbrew/.linuxbrew && chmod -R g+w /home/linuxbrew/.linuxbrew
# END Install Homebrew

# DO NOT upgrade system pip on Debian (PEP 668). Use venv at runtime.

USER node
