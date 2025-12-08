#!/usr/bin/env bash
set -euo pipefail

export PATH="$PATH:/root/.pub-cache/bin"

# Ensure Flutter web is enabled and dependencies are installed
echo "[entrypoint] Enabling Flutter web support (idempotent)..."
flutter config --enable-web >/dev/null 2>&1 || true

echo "[entrypoint] Fetching pub dependencies..."
flutter pub get

# Build release assets (forces rebuild to ensure latest code)
echo "[entrypoint] Building Flutter web bundle (release)..."
flutter build web --release

# Serve the built assets
echo "[entrypoint] Starting dhttpd web server on port 3000"
exec dhttpd --path build/web --host 0.0.0.0 --port 3000
