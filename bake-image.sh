#!/bin/bash
set -euo pipefail

SEED=/opt/workspace-internal/ComfyUI
PIP=/venv/main/bin/pip

# Single source of truth for the node list: the provisioning script
eval "$(sed -n '/^NODES=(/,/^)/p' /tmp/provision-minimax-h3.sh)"

echo "== Updating Vast's seed copy of ComfyUI to v0.38.2 =="
cd "$SEED"
# Fetch ONLY the specific tag, keeping it shallow
git fetch --depth 1 origin tag v0.38.2
git checkout FETCH_HEAD

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