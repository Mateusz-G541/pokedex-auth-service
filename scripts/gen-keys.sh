#!/usr/bin/env bash
set -euo pipefail

# Generate RSA keys using Node's crypto (no OpenSSL dependency)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_BIN="node"

if ! command -v "$NODE_BIN" >/dev/null 2>&1; then
  echo "[gen-keys.sh] Node.js is required to run this script" >&2
  exit 1
fi

"$NODE_BIN" "$SCRIPT_DIR/gen-keys.js"
