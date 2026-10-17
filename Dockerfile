# 1. Inherit Vast's highly optimized image
FROM vastai/comfy:v0.37.0-cuda-13.2-py312

# 2. Switch to root to install Node.js and aria2
USER root
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get update && apt-get install -y --no-install-recommends \
    nodejs aria2 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 3. Install Heavy Node Dependencies 
# (Doing this here caches the 3.8GB TensorRT library so the provisioning script is lightning fast)
RUN /venv/main/bin/pip install --no-cache-dir huggingface_hub hf_transfer \
    opencv-python-headless imageio imageio-ffmpeg tensorrt tensorrt-cu13 onnxruntime-gpu

WORKDIR /workspace