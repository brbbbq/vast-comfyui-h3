#!/bin/bash
set -euo pipefail

SEED=/opt/workspace-internal/ComfyUI
PIP=/venv/main/bin/pip

# Single source of truth for the node list: the provisioning script
eval "$(sed -n '/^NODES=(/,/^)/p' /tmp/provision-minimax-h3.sh)"

echo "== Updating Vast's seed copy of ComfyUI to latest master =="
cd "$SEED"
git fetch --depth 1 https://github.com/comfyanonymous/ComfyUI.git master
git checkout -B master FETCH_HEAD

$PIP install --no-cache-dir -r requirements.txt
$PIP install --no-cache-dir -r manager_requirements.txt || true

mkdir -p custom_nodes
for repo in "${NODES[@]}"; do
    dir="${repo##*/}"
    path="custom_nodes/${dir}"
    if [ ! -d "$path" ]; then
        echo "Cloning ${dir}..."
        git clone --depth 1 --recursive --shallow-submodules "$repo" "$path"
    fi
    if [ -f "$path/requirements.txt" ]; then
        $PIP install --no-cache-dir -r "$path/requirements.txt" || echo "WARN: requirements failed for ${dir}"
    fi
done