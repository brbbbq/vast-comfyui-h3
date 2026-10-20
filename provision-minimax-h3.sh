#!/bin/bash
echo "=== Starting Custom Node Provisioning ==="

COMFYUI_DIR="/workspace/ComfyUI"
SEED_DIR="/opt/workspace-internal/ComfyUI"
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
    "https://github.com/LBH-123-AI/Comfyui_Minimax_h3_latent_Upscaler"
    "https://github.com/chanon/comfyui-obvpm-timeline"
    "https://github.com/chanon/comfyui-obvpm"
)

# 1. Make sure ComfyUI is in /workspace (diagnostic line shows what exists)
echo "Checking ComfyUI core..."
ls -d "${COMFYUI_DIR}" "${COMFYUI_DIR}/main.py" "${COMFYUI_DIR}/.git" 2>&1 | sed 's/^/  /'

if [ ! -f "${COMFYUI_DIR}/main.py" ]; then
    mkdir -p "${COMFYUI_DIR}"
    if [ -d "${SEED_DIR}" ]; then
        echo "Seeding ComfyUI from image copy..."
        # This rsync safely merges the baked files into the folder, even if start-models.sh is already running
        rsync -a --ignore-existing "${SEED_DIR}/" "${COMFYUI_DIR}/"
    else
        echo "No image copy found; shallow-cloning ComfyUI..."
        git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git /tmp/ComfyUI_core
        cp -a /tmp/ComfyUI_core/. "${COMFYUI_DIR}/"
        rm -rf /tmp/ComfyUI_core
    fi
fi

# 2. Enforce ComfyUI pinned version
if [ -d "${COMFYUI_DIR}/.git" ]; then
    echo "Enforcing ComfyUI version v0.38.2..."
    # Check out the tag; if we don't have it, shallow fetch it and reset
    (cd "${COMFYUI_DIR}" && git checkout v0.38.2 2>/dev/null || \
    (git fetch --depth 1 origin tag v0.38.2 && git reset --hard FETCH_HEAD)) \
        || echo "WARN: git update failed, continuing with existing version"
fi

# Near-instant when baked into the image; only downloads what changed since the build
$VENV_PIP install --no-cache-dir -r "${COMFYUI_DIR}/requirements.txt"
$VENV_PIP install --no-cache-dir -r "${COMFYUI_DIR}/manager_requirements.txt" || true

# 3. Download and Update Custom Nodes
mkdir -p "${COMFYUI_DIR}/custom_nodes"
for repo in "${NODES[@]}"; do
    dir="${repo##*/}"
    path="${COMFYUI_DIR}/custom_nodes/${dir}"
    requirements="${path}/requirements.txt"

    if [[ -d $path ]]; then
        printf "Updating node: %s...\n" "${dir}"
        # Keep the fetch shallow! Only grab the absolute latest commit.
        ( cd "$path" && git fetch --depth 1 origin HEAD && git reset --hard FETCH_HEAD ) || echo "WARN: pull failed for ${dir}"
    else
        printf "Downloading node: %s...\n" "${dir}"
        git clone --depth 1 --recursive --shallow-submodules "${repo}" "${path}"
    fi

    if [[ -e $requirements ]]; then
        printf "Installing requirements for %s...\n" "${dir}"
        $VENV_PIP install --no-cache-dir -r "${requirements}" || true
    fi
done

chown -R workspace:workspace "${COMFYUI_DIR}/custom_nodes" 2>/dev/null || true

echo "=== Provisioning Complete! ==="