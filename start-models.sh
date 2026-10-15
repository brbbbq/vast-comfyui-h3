#!/bin/bash
echo "=== Starting Vast ComfyUI Setup ==="

# 1. If main.py isn't in /workspace/ComfyUI, safely merge core ComfyUI into it
if [ ! -f "/workspace/ComfyUI/main.py" ] || ! grep -q "0.38\|0.39" /workspace/ComfyUI/comfy_extras/xxx.py 2>/dev/null; then
    echo "Updating ComfyUI core for Veda compatibility..."
    git clone https://github.com/comfyanonymous/ComfyUI.git /tmp/ComfyUI_core
    cp -rn /tmp/ComfyUI_core/* /workspace/ComfyUI/
    cp -n /tmp/ComfyUI_core/.* /workspace/ComfyUI/ 2>/dev/null || true
    rm -rf /tmp/ComfyUI_core
fi

# 2. Ensure target model directories exist
mkdir -p /workspace/ComfyUI/models/diffusion_models \
         /workspace/ComfyUI/models/unet \
         /workspace/ComfyUI/models/text_encoders \
         /workspace/ComfyUI/models/vae \
         /workspace/ComfyUI/models/loras \
         /workspace/ComfyUI/models/veda

# 3. Enable HF Transfer & Run Model Downloads
export HF_HUB_ENABLE_HF_TRANSFER=1
echo "--> Downloading Hugging Face models..."

python3 -c "
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

# --- MINIMAX H3 MODELS ---
get_hf_model('Comfy-Org/MiniMax-H3', 'diffusion_models/minimax_h3_ref2va_pruned_int8_convrot.safetensors', '/workspace/ComfyUI/models/unet')
# get_hf_model('smhfacct/Minimax-H3-fl2va-ref2va-hybrid-models', 'minimax_h3_hybrid_fl2va_ref2va_b25-49-int8.safetensors', '/workspace/ComfyUI/models/unet')
get_hf_model('Comfy-Org/MiniMax-H3', 'text_encoders/qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors', '/workspace/ComfyUI/models/text_encoders')
get_hf_model('Comfy-Org/MiniMax-H3', 'vae/minimax_h3_video_vae_int8_convrot.safetensors', '/workspace/ComfyUI/models/vae')
get_hf_model('Comfy-Org/MiniMax-H3', 'vae/minimax_h3_audio_vae_fp32.safetensors', '/workspace/ComfyUI/models/vae')

# --- TURBO LORAS ---
get_hf_model('lightx2v/Minimax-h3-Turbo', 'minimax_h3_ref2v_turbo_4step_v0.1_comfyui_bf16.safetensors', '/workspace/ComfyUI/models/loras')
# get_hf_model('t8star/MiniMax-H3-Acc-8Step-comfy', 'MiniMax-H3-Ref2VA-Acc-8Step_comfyui_pdd-T8.safetensors', '/workspace/ComfyUI/models/loras')

# --- VEDA PREDICTOR ---
get_hf_model('Veda-Sparse/Minimax-H3-T2VA-Veda-8NFE-600Step-Preview', 'minimax_h3_t2va_veda_8nfe_600step_preview_fp8.safetensors', '/workspace/ComfyUI/models/veda')

# --- MINIMAX H3 TENSORRT VAE (ONNX Base Files) ---
# get_hf_model('lihaoyun6/MiniMax-H3-VAE-ONNX', 'minimax_h3_vae_decoder.onnx', '/workspace/ComfyUI/models/vae')
# get_hf_model('lihaoyun6/MiniMax-H3-VAE-ONNX', 'minimax_h3_vae_decoder.onnx.data', '/workspace/ComfyUI/models/vae')
# get_hf_model('lihaoyun6/MiniMax-H3-VAE-ONNX', 'minimax_h3_vae_encoder.onnx', '/workspace/ComfyUI/models/vae')
"

echo "Model downloads complete!"

echo "Restarting ComfyUI service..."
supervisorctl update
supervisorctl restart comfyui || supervisorctl start comfyui