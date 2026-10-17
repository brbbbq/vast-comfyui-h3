#!/bin/bash
echo "=== Starting Custom Node Provisioning ==="

COMFYUI_DIR="/workspace/ComfyUI"
VENV_PIP="/venv/main/bin/pip"

NODES=(
    "https://github.com/rgthree/rgthree-comfy"
    "https://github.com/kijai/ComfyUI-KJNodes"
    "https://github.com/chrisgoringe/cg-use-everywhere"
    "https://github.com/slahiri/ComfyUI-Workflow-Models-Downloader"
    "https://github.com/kosinkadink/ComfyUI-VideoHelperSuite"
    "https://github.com/xmarre/ComfyUI-Spectrum-MiniMax-H3"
    "https://github.com/lihaoyun6/ComfyUI-H3VAE_TRT"
    "https://github.com/veda-sparse/Veda-on-ComfyUI"
    "https://github.com/Zironic/H3-Optimizations"
    "https://github.com/xmarre/Comfyui_Minimax_h3_latent_Upscaler-Plus"
)

# 1. Safely Install / Update ComfyUI Core
echo "Ensuring ComfyUI core is installed and up to date..."
if [ ! -f "${COMFYUI_DIR}/main.py" ] || [ ! -d "${COMFYUI_DIR}/.git" ]; then
    echo "ComfyUI core missing due to volume mount. Installing..."
    git clone https://github.com/comfyanonymous/ComfyUI.git /tmp/ComfyUI_core
    cp -r /tmp/ComfyUI_core/* ${COMFYUI_DIR}/
    cp -r /tmp/ComfyUI_core/.* ${COMFYUI_DIR}/ 2>/dev/null || true
    rm -rf /tmp/ComfyUI_core
else
    echo "ComfyUI exists. Updating via git pull..."
    (cd ${COMFYUI_DIR} && git pull origin master)
fi

# CRITICAL: Install ComfyUI's core requirements (fixes the comfy_kitchen crash)
$VENV_PIP install --no-cache-dir -r ${COMFYUI_DIR}/requirements.txt
$VENV_PIP install --no-cache-dir -U comfyui-manager
$VENV_PIP install --no-cache-dir -r ${COMFYUI_DIR}/manager_requirements.txt || true

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

# Ensure permissions are correct
chown -R workspace:workspace "${COMFYUI_DIR}/custom_nodes" 2>/dev/null || true

echo "=== Provisioning Complete! ==="