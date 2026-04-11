#!/usr/bin/env bash
# =============================================================================
# UNICC AI Safety Lab – Start MoE Orchestrator
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

VENV_DIR="$PROJECT_ROOT/.venv"
LOG_DIR="$PROJECT_ROOT/logs"
API_PORT=8010
LOG_FILE="$LOG_DIR/moe.log"

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

echo "[MOE] Starting MoE Orchestrator on port $API_PORT..."
echo "[MOE] Project Root → $PROJECT_ROOT"
echo "[MOE] Logs         → $LOG_FILE"
echo "[MOE] API Docs     → http://localhost:$API_PORT/docs"
echo ""

cd "$PROJECT_ROOT"

uvicorn modules.moe_orchestrator:app \
  --host 0.0.0.0 \
  --port "$API_PORT" \
  --reload \
  --log-level info \
  2>&1 | tee "$LOG_FILE"
