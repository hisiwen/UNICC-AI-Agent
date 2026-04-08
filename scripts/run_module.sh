#!/usr/bin/env bash
# =============================================================================
# UNICC AI Safety Lab – Start Expert Module 1 (Pillar 1)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

VENV_DIR="$PROJECT_ROOT/.venv"
LOG_DIR="$PROJECT_ROOT/logs"
API_PORT=8000
APP_MODULE="modules.expert_module:app"
LOG_FILE="$LOG_DIR/module1.log"

mkdir -p "$LOG_DIR"

if [ ! -d "$VENV_DIR" ]; then
  echo "[ERROR] Virtual environment not found at $VENV_DIR"
  echo "[ERROR] Run ./setup.sh first."
  exit 1
fi

source "$VENV_DIR/bin/activate"

if ! command -v uvicorn >/dev/null 2>&1; then
  echo "[ERROR] uvicorn is not installed in $VENV_DIR"
  echo "[ERROR] Run ./setup.sh again or install dependencies manually."
  exit 1
fi

echo "[MODULE] Starting Expert Module 1 on port $API_PORT..."
echo "[MODULE] Project Root → $PROJECT_ROOT"
echo "[MODULE] Virtualenv   → $VENV_DIR"
echo "[MODULE] Logs         → $LOG_FILE"
echo "[MODULE] API Docs     → http://localhost:$API_PORT/docs"
echo ""

cd "$PROJECT_ROOT"

uvicorn "$APP_MODULE" \
  --host 0.0.0.0 \
  --port "$API_PORT" \
  --reload \
  --log-level info \
  2>&1 | tee "$LOG_FILE"
