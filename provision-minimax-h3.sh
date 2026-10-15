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

# 1. Update ComfyUI Core & missing PIP requirements
if [ ! -f "${COMFYUI_DIR}/main.py" ] || ! grep -q "0.38\|0.39" "${COMFYUI_DIR}/comfy_extras/xxx.py" 2>/dev/null; then
    echo "Updating ComfyUI core for Veda compatibility..."
    git clone https://github.com/comfyanonymous/ComfyUI.git /tmp/ComfyUI_core
    cp -rn /tmp/ComfyUI_core/* ${COMFYUI_DIR}/
    cp -n /tmp/ComfyUI_core/.* ${COMFYUI_DIR}/ 2>/dev/null || true
    rm -rf /tmp/ComfyUI_core
    
    # CRITICAL FIX: Update the frontend and core pip dependencies
    $VENV_PIP install --no-cache-dir -r ${COMFYUI_DIR}/requirements.txt
fi

# 2. Download and Update Custom Nodes
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
        $VENV_PIP install --no-cache-dir -r "${requirements}" || true
    fi
done

# Ensure permissions are correct if AI-Dock runs this as root
chown -R workspace:workspace "${COMFYUI_DIR}/custom_nodes" 2>/dev/null || true

echo "=== Provisioning Complete! ==="