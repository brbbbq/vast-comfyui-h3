#!/bin/bash
echo "=== Starting Custom Node Provisioning ==="

COMFYUI_DIR="/workspace/ComfyUI"
VENV_PIP="/venv/main/bin/pip"

NODES=(
    "https://github.com/xmarre/ComfyUI-Spectrum-MiniMax-H3"
    "https://github.com/lihaoyun6/ComfyUI-H3VAE_TRT"
    "https://github.com/veda-sparse/Veda-on-ComfyUI"
    "https://github.com/Zironic/H3-Optimizations"
    "https://github.com/xmarre/Comfyui_Minimax_h3_latent_Upscaler-Plus"
)

# Download and Update Custom Nodes
mkdir -p "${COMFYUI_DIR}/custom_nodes"
for repo in "${NODES[@]}"; do
    dir="${repo##*/}"
    path="${COMFYUI_DIR}/custom_nodes/${dir}"
    requirements="${path}/requirements.txt"
    
    if [[ -d $path ]]; then
        printf "Updating node: %s...\n" "${dir}"
        ( cd "$path" && git pull )
    else
        printf "Downloading node: %s...\n" "${dir}"
        git clone "${repo}" "${path}" --recursive
    fi
    
    if [[ -e $requirements ]]; then
        printf "Installing requirements for %s...\n" "${dir}"
        # This will now run instantly because heavy packages are in the Docker image
        $VENV_PIP install --no-cache-dir -r "${requirements}" || true
    fi
done

# Ensure permissions are correct
chown -R workspace:workspace "${COMFYUI_DIR}/custom_nodes" 2>/dev/null || true

echo "=== Provisioning Complete! ==="