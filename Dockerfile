# Use Ubuntu as base image
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_VERSION=20.11.0
ENV PYTHON_VERSION=3.11

# Update package list and install essential tools
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    software-properties-common \
    ca-certificates \
    gnupg \
    lsb-release \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Python 3.11
RUN add-apt-repository ppa:deadsnakes/ppa -y && \
    apt-get update && \
    apt-get install -y \
    python3.11 \
    python3.11-dev \
    python3.11-venv \
    python3.11-distutils \
    python3.11-tk \
    && rm -rf /var/lib/apt/lists/*

# Install pip manually for Python 3.11
RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python3.11

# Create symlinks for python and pip
RUN ln -sf /usr/bin/python3.11 /usr/bin/python3 && \
    ln -sf /usr/bin/python3.11 /usr/bin/python && \
    ln -sf /usr/local/bin/pip3.11 /usr/bin/pip

# Install Node.js LTS
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get install -y nodejs

# Install Yarn (optional but useful)
RUN npm install -g yarn

# Install Expo CLI and EAS CLI globally
RUN npm install -g @expo/cli@latest && \
    npm install -g eas-cli@latest

# Install Python packages commonly used in build processes
RUN python3.11 -m pip install --upgrade pip && \
    python3.11 -m pip install \
    requests \
    PyInstaller \
    pillow

# Create working directory
WORKDIR /app

# Copy package files first for better Docker layer caching
COPY package*.json ./

# Install Node.js dependencies
RUN npm install

# Copy the rest of the application
COPY . .

# Create a non-root user for security
RUN useradd -m -s /bin/bash appuser && \
    chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Set up environment
ENV PATH="/home/appuser/.local/bin:$PATH"

# Expose common development ports
EXPOSE 3000 8081 19000 19001 19002

# Default command
CMD ["bash"]