#!/usr/bin/env bash
<<<<<<< HEAD
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

cleanup() {
  jobs -p | xargs -r kill
}
trap cleanup EXIT

AGENT_CONFIG="configs/standards_compliance_agent.yaml" uvicorn agents.app:app --host 0.0.0.0 --port 8000 &
AGENT_CONFIG="configs/safety_dimensions_agent.yaml" uvicorn agents.app:app --host 0.0.0.0 --port 8001 &
AGENT_CONFIG="configs/assurance_accountability_agent.yaml" uvicorn agents.app:app --host 0.0.0.0 --port 8002 &
uvicorn orchestrator.app:app --host 0.0.0.0 --port 8080
=======
# =============================================================================
# UNICC AI Safety Lab – Run All Services
# Starts:
#   1. FastAPI Expert Module
#   2. UNICC AI Safety Sandbox UI
#   3. UNICC AI Agent
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

MAIN_VENV_DIR="$PROJECT_ROOT/.venv"
LOG_DIR="$PROJECT_ROOT/logs"

INTEGRATIONS_DIR="$PROJECT_ROOT/integrations"
RYAN_DIR="$INTEGRATIONS_DIR/unicc-ai-safety-sandbox-final"
AGENT_DIR="$INTEGRATIONS_DIR/unicc-ai-agent"
AGENT_VENV_DIR="$AGENT_DIR/.venv"

API_PORT=8000
RYAN_UI_PORT=5173
AGENT_UI_PORT=8501

APP_MODULE="modules.expert_module:app"

MODULE_LOG="$LOG_DIR/module1.log"
RYAN_LOG="$LOG_DIR/unicc_sandbox_ui.log"
AGENT_LOG="$LOG_DIR/unicc_agent.log"

mkdir -p "$LOG_DIR"

err() {
  echo "[ERROR] $1"
  exit 1
}

warn() {
  echo "[WARN] $1"
}

info() {
  echo "[RUN_ALL] $1"
}

[ -d "$MAIN_VENV_DIR" ] || err "Main virtualenv not found at $MAIN_VENV_DIR. Please run ./setup.sh first."
[ -d "$RYAN_DIR" ] || err "Ryan system repo not found at $RYAN_DIR. Please run ./setup.sh first."
[ -d "$AGENT_DIR" ] || err "Agent repo not found at $AGENT_DIR. Please run ./setup.sh first."
[ -d "$AGENT_VENV_DIR" ] || err "Agent virtualenv not found at $AGENT_VENV_DIR. Please run ./setup.sh first."

command -v bash >/dev/null 2>&1 || err "bash is required"
command -v npm >/dev/null 2>&1 || err "npm is required for the Ryan UI system"

if [ ! -f "$RYAN_DIR/.env.local" ]; then
  warn "Missing $RYAN_DIR/.env.local"
  warn "Ryan UI may fail unless VITE_GEMINI_API_KEY is configured."
fi

if [ ! -f "$AGENT_DIR/.env" ]; then
  warn "Missing $AGENT_DIR/.env"
  warn "UNICC AI Agent may fail unless API keys are configured."
fi

PIDS=()

cleanup() {
  echo ""
  info "Stopping all services..."
  for pid in "${PIDS[@]:-}"; do
    if kill -0 "$pid" >/dev/null 2>&1; then
      kill "$pid" >/dev/null 2>&1 || true
    fi
  done
  wait || true
  info "All services stopped."
}

trap cleanup INT TERM EXIT

info "Starting FastAPI Expert Module on port $API_PORT..."
(
  source "$MAIN_VENV_DIR/bin/activate"
  cd "$PROJECT_ROOT"
  uvicorn "$APP_MODULE" \
    --host 0.0.0.0 \
    --port "$API_PORT" \
    --reload \
    --log-level info
) 2>&1 | tee "$MODULE_LOG" &
PIDS+=($!)

sleep 2

info "Starting UNICC AI Safety Sandbox UI on port $RYAN_UI_PORT..."
(
  cd "$RYAN_DIR"
  npm run dev -- --host 0.0.0.0 --port "$RYAN_UI_PORT"
) 2>&1 | tee "$RYAN_LOG" &
PIDS+=($!)

sleep 2

info "Starting UNICC AI Agent on port $AGENT_UI_PORT..."
(
  source "$AGENT_VENV_DIR/bin/activate"
  cd "$AGENT_DIR"
  streamlit run appz.py --server.address 0.0.0.0 --server.port "$AGENT_UI_PORT"
) 2>&1 | tee "$AGENT_LOG" &
PIDS+=($!)

sleep 2

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  UNICC AI Safety Lab – All Services Running"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "FastAPI Expert Module:"
echo "  URL      → http://localhost:$API_PORT"
echo "  Docs     → http://localhost:$API_PORT/docs"
echo "  Log      → $MODULE_LOG"
echo ""
echo "UNICC AI Safety Sandbox UI:"
echo "  URL      → http://localhost:$RYAN_UI_PORT"
echo "  Log      → $RYAN_LOG"
echo ""
echo "UNICC AI Agent:"
echo "  URL      → http://localhost:$AGENT_UI_PORT"
echo "  Log      → $AGENT_LOG"
echo ""
echo "Press Ctrl+C to stop all services."
echo ""

wait
>>>>>>> a4acaf8c2ee31292256564047a1fc1c066fb836f
