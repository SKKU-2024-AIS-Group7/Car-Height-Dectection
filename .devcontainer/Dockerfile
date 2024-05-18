FROM mcr.microsoft.com/devcontainers/python:1-3.11

# Install AWS CLI
RUN architecture=$(dpkg --print-architecture) && if [ "$architecture" = "arm64" ]; then \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscli.zip"; \
    else \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscli.zip"; \
    fi \
    && unzip awscli.zip \
    && ./aws/install \
    && rm -rf aws awscli.zip