#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
ISO_DIR="$REPO_DIR/iso"
WORK_DIR="/tmp/nuitos-build"
OUT_DIR="$REPO_DIR/out"

echo "╔══════════════════════════════╗"
echo "║     NuitOS ISO Builder       ║"
echo "╚══════════════════════════════╝"
echo ""

# Check for root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: This script must be run as root (for archiso)"
    echo "Usage: sudo ./build.sh"
    exit 1
fi

# Check archiso is installed
if ! command -v mkarchiso &>/dev/null; then
    echo "ERROR: archiso is not installed"
    echo "Install with: sudo pacman -S archiso"
    exit 1
fi

# Clean previous build
echo "[1/4] Cleaning previous build..."
rm -rf "$WORK_DIR"
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

# Copy profile
echo "[2/4] Setting up build profile..."
mkdir -p "$WORK_DIR"
cp -r "$ISO_DIR"/* "$WORK_DIR/"

# Generate locale
echo "[3/4] Generating locale..."
arch-chroot "$WORK_DIR/airootfs" locale-gen 2>/dev/null || true

# Build ISO
echo "[4/4] Building ISO..."
mkarchiso -v -w "$WORK_DIR" -o "$OUT_DIR" "$WORK_DIR"

echo ""
echo "═══════════════════════════════════════"
echo "Build complete!"
echo "ISO location: $OUT_DIR"
echo "═══════════════════════════════════════"
ls -lh "$OUT_DIR"/*.iso 2>/dev/null || echo "No ISO found - check build logs"
