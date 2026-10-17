#!/bin/bash
echo "=== Starting Background Model Downloads ==="

# 1. If main.py isn't in /workspace/ComfyUI, safely merge core ComfyUI into it
if [ ! -f "/workspace/ComfyUI/main.py" ] || ! grep -q "0.38\|0.39" /workspace/ComfyUI/comfy_extras/xxx.py 2>/dev/null; then
    echo "Updating ComfyUI core for Veda compatibility..."
    git clone https://github.com/comfyanonymous/ComfyUI.git /tmp/ComfyUI_core
    cp -rn /tmp/ComfyUI_core/* /workspace/ComfyUI/
    cp -n /tmp/ComfyUI_core/.* /workspace/ComfyUI/ 2>/dev/null || true
    rm -rf /tmp/ComfyUI_core
fi

# Ensure target model directories exist
mkdir -p /workspace/ComfyUI/models/diffusion_models \
         /workspace/ComfyUI/models/unet \
         /workspace/ComfyUI/models/text_encoders \
         /workspace/ComfyUI/models/vae \
         /workspace/ComfyUI/models/loras \
         /workspace/ComfyUI/models/veda \
         /workspace/ComfyUI/models/latent_upscale_models

# Disable HF Transfer to prevent the I/O crash on massive models
export HF_HUB_ENABLE_HF_TRANSFER=0
echo "--> Downloading Hugging Face models..."

# Use the specific virtual environment python
/venv/main/bin/python3 -c "
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

COMFYUI_DIR = '/workspace/ComfyUI'

# --- MINIMAX H3 MODELS ---
get_hf_model('Comfy-Org/MiniMax-H3', 'diffusion_models/minimax_h3_ref2va_pruned_int8_convrot.safetensors', f'{COMFYUI_DIR}/models/unet')
get_hf_model('Comfy-Org/MiniMax-H3', 'text_encoders/qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors', f'{COMFYUI_DIR}/models/text_encoders')
get_hf_model('Comfy-Org/MiniMax-H3', 'vae/minimax_h3_video_vae_int8_convrot.safetensors', f'{COMFYUI_DIR}/models/vae')
get_hf_model('Comfy-Org/MiniMax-H3', 'vae/minimax_h3_audio_vae_fp32.safetensors', f'{COMFYUI_DIR}/models/vae')

# --- TURBO LORAS ---
get_hf_model('lightx2v/Minimax-h3-Turbo', 'minimax_h3_ref2v_turbo_4step_v0.1_comfyui_bf16.safetensors', f'{COMFYUI_DIR}/models/loras')

# --- VEDA PREDICTOR ---
get_hf_model('Veda-Sparse/Minimax-H3-T2VA-Veda-8NFE-600Step-Preview', 'minimax_h3_t2va_veda_8nfe_600step_preview_fp8.safetensors', f'{COMFYUI_DIR}/models/veda')

# --- MINIMAX H3 LATENT UPSCALER ---
get_hf_model('LBH-123-AI/Minimax_h3_latent_Upscaler', 'minimax_h3_latent_upscaler_3d_conv_v1/minimax_h3_latent_upscaler_3d_conv_v1_bf16.safetensors', f'{COMFYUI_DIR}/models/latent_upscale_models')
"

echo "Model downloads complete!"

# Give the container 15 seconds to ensure supervisor is fully booted, then restart ComfyUI
sleep 15
supervisorctl restart comfyui || echo "ComfyUI not running yet, skipping restart"