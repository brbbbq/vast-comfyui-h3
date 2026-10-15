#!/bin/bash

# Configuration
COMFYUI_DIR="/workspace/ComfyUI"
VENV_PIP="/venv/main/bin/pip"
VENV_PYTHON="/venv/main/bin/python3"

# Template-specific Custom Nodes
NODES=(
    "https://github.com/xmarre/ComfyUI-Spectrum-MiniMax-H3"
    "https://github.com/lihaoyun6/ComfyUI-H3VAE_TRT"
    "https://github.com/veda-sparse/Veda-on-ComfyUI"
    "https://github.com/Zironic/H3-Optimizations"
)

function provisioning_start() {
    printf "\n=== Starting Vast ComfyUI Provisioning for MiniMax H3 ===\n"
    
    provisioning_update_comfyui_core
    provisioning_get_nodes
    provisioning_get_models
    
    printf "\n=== Provisioning Complete! ===\n"
    
    # Restarting ComfyUI to register new nodes and models
    echo "Restarting ComfyUI service..."
    supervisorctl update
    supervisorctl restart comfyui || supervisorctl start comfyui
}

function provisioning_update_comfyui_core() {
    # If main.py isn't in /workspace/ComfyUI, safely merge core ComfyUI into it
    if [ ! -f "${COMFYUI_DIR}/main.py" ] || ! grep -q "0.38\|0.39" "${COMFYUI_DIR}/comfy_extras/xxx.py" 2>/dev/null; then
        echo "Updating ComfyUI core for Veda compatibility..."
        git clone https://github.com/comfyanonymous/ComfyUI.git /tmp/ComfyUI_core
        cp -rn /tmp/ComfyUI_core/* ${COMFYUI_DIR}/
        cp -n /tmp/ComfyUI_core/.* ${COMFYUI_DIR}/ 2>/dev/null || true
        rm -rf /tmp/ComfyUI_core
    fi
}

function provisioning_get_nodes() {
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
}

function provisioning_get_models() {
    echo "Creating target model directories..."
    mkdir -p ${COMFYUI_DIR}/models/diffusion_models \
             ${COMFYUI_DIR}/models/unet \
             ${COMFYUI_DIR}/models/text_encoders \
             ${COMFYUI_DIR}/models/vae \
             ${COMFYUI_DIR}/models/loras \
             ${COMFYUI_DIR}/models/veda

    export HF_HUB_ENABLE_HF_TRANSFER=1
    echo "--> Downloading Hugging Face models..."

    $VENV_PYTHON -c "
import os
from huggingface_hub import hf_hub_download

def get_hf_model(repo_id, filename, target_dir):
    print(f'Downloading {os.path.basename(filename)}...')
    try:
        cached_path = hf_hub_download(
            repo_id=repo_id, 
            filename=filename, 
            token=os.environ.get('HF_TOKEN'),
            cache_dir='/workspace/huggingface_cache'
        )
        target_path = os.path.join(target_dir, os.path.basename(filename))
        if os.path.lexists(target_path):
            os.remove(target_path)
        os.symlink(cached_path, target_path)
        print(f'Ready: {target_path}')
    except Exception as e:
        print(f'Error downloading {filename}: {e}')

COMFYUI_DIR = '${COMFYUI_DIR}'

# --- MINIMAX H3 MODELS ---
get_hf_model('Comfy-Org/MiniMax-H3', 'diffusion_models/minimax_h3_ref2va_pruned_int8_convrot.safetensors', f'{COMFYUI_DIR}/models/unet')
get_hf_model('Comfy-Org/MiniMax-H3', 'text_encoders/qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors', f'{COMFYUI_DIR}/models/text_encoders')
get_hf_model('Comfy-Org/MiniMax-H3', 'vae/minimax_h3_video_vae_int8_convrot.safetensors', f'{COMFYUI_DIR}/models/vae')
get_hf_model('Comfy-Org/MiniMax-H3', 'vae/minimax_h3_audio_vae_fp32.safetensors', f'{COMFYUI_DIR}/models/vae')

# --- TURBO LORAS ---
get_hf_model('lightx2v/Minimax-h3-Turbo', 'minimax_h3_ref2v_turbo_4step_v0.1_comfyui_bf16.safetensors', f'{COMFYUI_DIR}/models/loras')

# --- VEDA PREDICTOR ---
get_hf_model('Veda-Sparse/Minimax-H3-T2VA-Veda-8NFE-600Step-Preview', 'minimax_h3_t2va_veda_8nfe_600step_preview_fp8.safetensors', f'{COMFYUI_DIR}/models/veda')
"
}

provisioning_start