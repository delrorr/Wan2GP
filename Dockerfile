FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git wget build-essential zlib1g-dev libssl-dev libffi-dev \
    libsqlite3-dev libbz2-dev libreadline-dev libncursesw5-dev \
    liblzma-dev tk-dev ffmpeg libsndfile1-dev libgl1 \
    && rm -rf /var/lib/apt/lists/*

# Build Python 3.10.9 from source
RUN wget https://www.python.org/ftp/python/3.10.9/Python-3.10.9.tgz && \
    tar -xzf Python-3.10.9.tgz && cd Python-3.10.9 && \
    ./configure --enable-optimizations && \
    make -j$(nproc) && make altinstall && \
    cd .. && rm -rf Python-3.10.9*

# Ensure python points to 3.10.9
RUN ln -sf /usr/local/bin/python3.10 /usr/bin/python && \
    ln -sf /usr/local/bin/python3.10 /usr/bin/python3 && \
    python --version

# Upgrade pip
RUN python -m ensurepip && python -m pip install --upgrade pip

# Create non-root user (for entrypoint)
RUN useradd -m -s /bin/bash user
USER root

# Clone repo
RUN git clone https://github.com/deepbeepmeep/Wan2GP.git .

# Copy custom entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Install PyTorch + requirements
RUN pip install --no-cache-dir torch==2.7.0 torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/test/cu128 \
    && pip install --no-cache-dir -r requirements.txt

# Ensure cache dirs exist for HuggingFace
RUN mkdir -p /home/user/.cache/huggingface && chown -R user:user /home/user

# Entrypoint
ENTRYPOINT ["/entrypoint.sh"]
