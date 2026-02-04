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
 && rm -rf /var/lib/apt/lists/*

# Some tooling expects `python`
RUN ln -sf /usr/bin/python3 /usr/local/bin/python

# DO NOT upgrade system pip on Debian (PEP 668). Use venv at runtime.

USER node
