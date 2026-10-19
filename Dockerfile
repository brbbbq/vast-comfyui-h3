# 1. Inherit Vast's highly optimized image
FROM vastai/comfy:v0.37.0-cuda-13.2-py312

# 2. Switch to root to install Node.js and aria2
USER root
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get update && apt-get install -y --no-install-recommends \
    nodejs aria2 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 3. Install Heavy Node Dependencies
RUN /venv/main/bin/pip install --no-cache-dir huggingface_hub hf_transfer \
    opencv-python-headless imageio imageio-ffmpeg tensorrt tensorrt-cu13 onnxruntime-gpu

# 4. Update Vast's seed copy of ComfyUI + bake custom nodes
COPY provision-minimax-h3.sh bake-image.sh /tmp/
ARG CACHEBUST=0
RUN bash /tmp/bake-image.sh && rm -f /tmp/bake-image.sh /tmp/provision-minimax-h3.sh

WORKDIR /workspace