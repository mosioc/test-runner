FROM ubuntu:22.04

# prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# install base dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    python3 \
    python3-pip \
    nodejs \
    npm \
    golang \
    jq \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# install test frameworks
RUN npm install -g jest@latest --no-optional --silent 2>&1 | tail -1

RUN pip3 install --upgrade pip setuptools wheel \
    && pip3 install pytest pytest-html --no-cache-dir

# create test runner script directory
WORKDIR /runner

# copy the test runner script
COPY test-runner.sh /runner/test-runner.sh
RUN chmod +x /runner/test-runner.sh

# set the entrypoint
ENTRYPOINT ["/runner/test-runner.sh"]
CMD ["--help"]
