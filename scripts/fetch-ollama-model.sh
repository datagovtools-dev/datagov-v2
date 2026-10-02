#!/bin/sh
# ──────────────────────────────────────────────────────────────────────────────
# Download an Ollama model over ONE resumable connection (slow / unstable networks)
#
# `ollama pull` downloads the weights in 16 parallel parts. On a slow connection
# (e.g. ~8 Mbps Wi-Fi) every part stalls and restarts from 0, so the pull never
# finishes. This script downloads the weights file with a single resumable curl
# connection, verifies its sha256, places it in Ollama's blob store, and then runs
# `ollama pull`, which only has to fetch the small remaining layers.
#
# Usage (from the project root, Ollama container running):
#   docker cp scripts/fetch-ollama-model.sh ag_ollama:/tmp/fetch-ollama-model.sh
#   docker exec ag_ollama sh /tmp/fetch-ollama-model.sh llama3.2 3b
#
# Safe to re-run: an interrupted download resumes; an installed blob is not re-downloaded.
# ──────────────────────────────────────────────────────────────────────────────
set -u

MODEL="${1:?usage: fetch-ollama-model.sh <model> <tag>   e.g. llama3.2 3b}"
TAG="${2:?usage: fetch-ollama-model.sh <model> <tag>   e.g. llama3.2 3b}"
case "$MODEL" in */*) REPO="$MODEL" ;; *) REPO="library/$MODEL" ;; esac
REGISTRY="https://registry.ollama.ai/v2/$REPO"
BLOBS=/root/.ollama/models/blobs

if ! command -v curl >/dev/null 2>&1; then
  echo "Installing curl..."
  apt-get update -qq >/dev/null 2>&1 && apt-get install -y -qq curl >/dev/null 2>&1 || { echo "ERROR: curl not available"; exit 1; }
fi

# 1. Read the manifest to find the model weights layer (digest + size)
MANIFEST=$(curl -sfL -H "Accept: application/vnd.docker.distribution.manifest.v2+json" "$REGISTRY/manifests/$TAG") \
  || { echo "ERROR: could not read manifest for $MODEL:$TAG"; exit 1; }
LAYER=$(echo "$MANIFEST" | tr -d ' \n' | grep -o '"mediaType":"application/vnd.ollama.image.model","digest":"sha256:[0-9a-f]*","size":[0-9]*')
HEX=$(echo "$LAYER" | sed 's/.*sha256:\([0-9a-f]*\).*/\1/')
SIZE=$(echo "$LAYER" | sed 's/.*"size":\([0-9]*\).*/\1/')
[ -n "$HEX" ] && [ -n "$SIZE" ] || { echo "ERROR: model layer not found in manifest"; exit 1; }
echo "Model $MODEL:$TAG weights: sha256:$HEX ($((SIZE / 1048576)) MB)"

BLOB="$BLOBS/sha256-$HEX"
TMP="$BLOBS/manual-$HEX.download"

# 2. Download over one connection, resuming after drops
if [ -f "$BLOB" ]; then
  echo "Weights already installed, skipping download."
else
  attempt=0
  while :; do
    have=$(stat -c %s "$TMP" 2>/dev/null || echo 0)
    [ "$have" -ge "$SIZE" ] && break
    attempt=$((attempt + 1))
    echo "attempt $attempt: resuming at $((have / 1048576)) MB of $((SIZE / 1048576)) MB"
    # abort a connection that drops below 50 KB/s for 60 s, then resume
    curl -sfL -C - --connect-timeout 30 --speed-limit 51200 --speed-time 60 -o "$TMP" "$REGISTRY/blobs/sha256:$HEX" || sleep 5
  done

  # 3. Verify and install the blob
  echo "Download complete, verifying sha256..."
  GOT=$(sha256sum "$TMP" | cut -d' ' -f1)
  if [ "$GOT" != "$HEX" ]; then
    echo "ERROR: checksum mismatch (got $GOT); deleting the download so it can be retried"
    rm -f "$TMP"
    exit 1
  fi
  mv "$TMP" "$BLOB"
  rm -f "$BLOB-partial" "$BLOB"-partial-*   # leftovers from failed `ollama pull` attempts
  echo "Weights verified and installed."
fi

# 4. Let Ollama fetch the small layers (template, license, params) and register the model
ollama pull "$MODEL:$TAG" || exit 1
ollama list | grep -q "^$MODEL:$TAG" && echo "READY: $MODEL:$TAG is installed"
