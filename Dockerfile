# 1. Inherit Vast's highly optimized image (Includes Syncthing, Jupyter, SSH, and ComfyUI)
FROM vastai/comfy:v0.37.0-cuda-13.2-py312

# 2. Switch to root to install Node.js and aria2
USER root
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get update && apt-get install -y --no-install-recommends \
    nodejs aria2 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Define where Vast keeps ComfyUI
ENV COMFYUI_DIR=/workspace/ComfyUI

# 3. Clone Custom Nodes (Vast already installed core ComfyUI, so we skip that)
WORKDIR ${COMFYUI_DIR}/custom_nodes
RUN git clone https://github.com/rgthree/rgthree-comfy.git && cd rgthree-comfy && git checkout 2c5342a && cd .. \
    && git clone https://github.com/kijai/ComfyUI-KJNodes.git && cd ComfyUI-KJNodes && git checkout 5710537 && cd .. \
    && git clone https://github.com/chrisgoringe/cg-use-everywhere.git && cd cg-use-everywhere && git checkout 50ae9f8 && cd .. \
    && git clone https://github.com/slahiri/ComfyUI-Workflow-Models-Downloader.git && cd ComfyUI-Workflow-Models-Downloader && git checkout c3ef4db && cd .. \
    && git clone https://github.com/xmarre/ComfyUI-Spectrum-MiniMax-H3.git \
    && git clone https://github.com/lihaoyun6/ComfyUI-H3VAE_TRT.git \
    && git clone https://github.com/veda-sparse/Veda-on-ComfyUI.git \
    && git clone https://github.com/kosinkadink/ComfyUI-VideoHelperSuite \
    && git clone https://github.com/Zironic/H3-Optimizations

# 4. Install Node Dependencies (--no-cache-dir prevents gigabytes of bloat)
RUN /venv/main/bin/pip install --no-cache-dir huggingface_hub hf_transfer \
    opencv-python-headless imageio imageio-ffmpeg tensorrt-cu12 onnxruntime-gpu \
    && pip install --no-cache-dir -r rgthree-comfy/requirements.txt || true \
    && pip install --no-cache-dir -r ComfyUI-KJNodes/requirements.txt || true \
    && pip install --no-cache-dir -r cg-use-everywhere/requirements.txt || true \
    && pip install --no-cache-dir -r ComfyUI-Workflow-Models-Downloader/requirements.txt || true \
    && pip install --no-cache-dir -r ComfyUI-H3VAE_TRT/requirements.txt || true \
    && pip install --no-cache-dir -r Veda-on-ComfyUI/requirements.txt || true \
    && pip install --no-cache-dir -r ComfyUI-VideoHelperSuite/requirements.txt || true \
    && pip install --no-cache-dir -r ${COMFYUI_DIR}/manager_requirements.txt || true \
    && rm -rf /root/.cache


# Return to workspace
WORKDIR /workspace