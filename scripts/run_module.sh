#!/usr/bin/env bash
# =============================================================================
# UNICC AI Safety Lab – Start Expert Module 1 (Pillar 1)
# =============================================================================
set -e

VENV_DIR="../.venv"
API_PORT=8000
LOG_DIR="../logs"

source "$VENV_DIR/bin/activate"

echo "[MODULE] Starting Expert Module 1 on port $API_PORT..."
echo "[MODULE] Logs → $LOG_DIR/module1.log"
echo "[MODULE] API Docs → http://localhost:$API_PORT/docs"
echo ""

uvicorn modules.expert_module:app \
  --host 0.0.0.0 \
  --port $API_PORT \
  --reload \
  --log-level info \
  2>&1 | tee "$LOG_DIR/module1.log"
