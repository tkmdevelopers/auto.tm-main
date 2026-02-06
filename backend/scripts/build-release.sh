#!/usr/bin/env bash
# =============================================================================
# build-release.sh — Build a versioned Docker image and assemble a release bundle
#
# Runs on your LOCAL machine (Mac/Linux with Docker).
# Reads the version from package.json, builds the image, exports a tar.gz,
# and assembles everything the server needs into a release/ directory.
#
# Usage:
#   cd backend
#   ./scripts/build-release.sh          # uses version from package.json
#   ./scripts/build-release.sh 0.3.0    # override version explicitly
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKEND_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
IMAGE_NAME="alpha-motors-backend"

# ---------------------------------------------------------------------------
# Resolve version
# ---------------------------------------------------------------------------

if [ -n "${1:-}" ]; then
  VERSION="$1"
else
  VERSION=$(node -p "require('$BACKEND_DIR/package.json').version")
fi

IMAGE_TAG="${IMAGE_NAME}:${VERSION}"
IMAGE_LATEST="${IMAGE_NAME}:latest"

echo "============================================="
echo "  Alpha Motors — Build Release v${VERSION}"
echo "============================================="
echo ""
echo "  Image:   ${IMAGE_TAG}"
echo "  Latest:  ${IMAGE_LATEST}"
echo ""

# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------

if ! command -v docker &>/dev/null; then
  echo "[error] Docker is not installed or not in PATH" >&2
  exit 1
fi

if ! docker info &>/dev/null; then
  echo "[error] Docker daemon is not running. Start Docker Desktop first." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Phase 1 — Build Docker image
# ---------------------------------------------------------------------------

echo "[1/4] Building Docker image..."
docker build \
  -t "$IMAGE_TAG" \
  -t "$IMAGE_LATEST" \
  -f "$BACKEND_DIR/Dockerfile" \
  "$BACKEND_DIR"

echo "  Done. Tagged as ${IMAGE_TAG} and ${IMAGE_LATEST}"

# ---------------------------------------------------------------------------
# Phase 2 — Export image to tar.gz
# ---------------------------------------------------------------------------

RELEASE_DIR="$BACKEND_DIR/release/alpha-motors-v${VERSION}"
mkdir -p "$RELEASE_DIR"

TAR_FILE="$RELEASE_DIR/${IMAGE_NAME}-${VERSION}.tar.gz"
echo ""
echo "[2/4] Saving image to ${TAR_FILE}..."
docker save "$IMAGE_TAG" "$IMAGE_LATEST" | gzip > "$TAR_FILE"

TAR_SIZE=$(du -h "$TAR_FILE" | cut -f1)
echo "  Done. Size: ${TAR_SIZE}"

# ---------------------------------------------------------------------------
# Phase 3 — Assemble release bundle
# ---------------------------------------------------------------------------

echo ""
echo "[3/4] Assembling release bundle..."

# Compose file
cp "$BACKEND_DIR/docker-compose.prod.yml" "$RELEASE_DIR/docker-compose.prod.yml"

# Environment template
cp "$BACKEND_DIR/.env.example" "$RELEASE_DIR/.env.example"

# Server-side scripts
mkdir -p "$RELEASE_DIR/scripts"
cp "$BACKEND_DIR/scripts/deploy-update.sh" "$RELEASE_DIR/deploy-update.sh"
chmod +x "$RELEASE_DIR/deploy-update.sh"
cp "$BACKEND_DIR/scripts/pg_backup.sh" "$RELEASE_DIR/scripts/pg_backup.sh"
chmod +x "$RELEASE_DIR/scripts/pg_backup.sh"

# Version marker
echo "$VERSION" > "$RELEASE_DIR/VERSION"

echo "  Done."

# ---------------------------------------------------------------------------
# Phase 4 — Summary
# ---------------------------------------------------------------------------

echo ""
echo "[4/4] Release bundle ready!"
echo ""
echo "  ${RELEASE_DIR}/"
ls -1 "$RELEASE_DIR" | while read -r f; do
  echo "    $f"
done
if [ -d "$RELEASE_DIR/scripts" ]; then
  ls -1 "$RELEASE_DIR/scripts" | while read -r f; do
    echo "    scripts/$f"
  done
fi

echo ""
echo "============================================="
echo "  Next steps:"
echo "============================================="
echo ""
echo "  1. Transfer the release folder to your server:"
echo ""
echo "     scp -r ${RELEASE_DIR} user@server-ip:/opt/alpha-motors/"
echo ""
echo "  2. On the server, run the update script:"
echo ""
echo "     cd /opt/alpha-motors/alpha-motors-v${VERSION}"
echo "     chmod +x deploy-update.sh"
echo "     ./deploy-update.sh ${IMAGE_NAME}-${VERSION}.tar.gz"
echo ""
echo "  For first-time deployment, copy .env.example to .env and"
echo "  edit it with your production secrets before running the update."
echo ""
