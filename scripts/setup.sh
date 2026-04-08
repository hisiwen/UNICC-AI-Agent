#!/usr/bin/env bash
# =============================================================================
# UNICC AI Safety Lab – Ollama + Llama 3.2 + Additional UNICC Systems Setup
# Author: Siwen Shen | NYU MASY GC-4100
# =============================================================================
# This script will:
#   1. Install/check Ollama
#   2. Pull Llama 3.2 (8B) model weights
#   3. Start the Ollama API server
#   4. Install Python dependencies for the FastAPI expert module
#   5. Clone and set up:
#        - RyanYang1390/unicc-ai-safety-sandbox-final
#        - hg3016-guo/unicc-ai-agent
#   6. Create helper launch scripts and environment templates
#
# Usage:
#   chmod +x setup.sh
#   ./setup.sh
# =============================================================================

set -euo pipefail

LLAMA_MODEL="llama3.2:8b"   # Change to llama3.2:3b if low on RAM (<16GB)
OLLAMA_PORT=11434
API_PORT=8000
RYAN_UI_PORT=5173
AGENT_UI_PORT=8501

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$ROOT_DIR/../logs"
VENV_DIR="$ROOT_DIR/../.venv"
INTEGRATIONS_DIR="$ROOT_DIR/../integrations"

RYAN_DIR="$INTEGRATIONS_DIR/unicc-ai-safety-sandbox-final"
AGENT_DIR="$INTEGRATIONS_DIR/unicc-ai-agent"
AGENT_VENV_DIR="$AGENT_DIR/.venv"

RYAN_REPO="https://github.com/RyanYang1390/unicc-ai-safety-sandbox-final.git"
AGENT_REPO="https://github.com/hg3016-guo/unicc-ai-agent.git"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${BLUE}[SETUP]${NC} $1"; }
ok()   { echo -e "${GREEN}[OK]${NC}    $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $1"; }
err()  { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || err "Missing required command: $1"
}

clone_or_update_repo() {
  local repo_url="$1"
  local target_dir="$2"

  if [ -d "$target_dir/.git" ]; then
    log "Updating existing repository: $target_dir"
    git -C "$target_dir" pull --ff-only
    ok "Repository updated: $target_dir"
  elif [ -d "$target_dir" ]; then
    warn "$target_dir exists but is not a git repository. Leaving it untouched."
  else
    log "Cloning repository: $repo_url"
    git clone "$repo_url" "$target_dir"
    ok "Repository cloned to $target_dir"
  fi
}

mkdir -p "$LOG_DIR" "$INTEGRATIONS_DIR"
log "Log directory ready at $LOG_DIR"
log "Integration directory ready at $INTEGRATIONS_DIR"

# ─── STEP 1: Detect OS ───────────────────────────────────────────────────────
log "Detecting operating system..."
OS="$(uname -s)"
case "$OS" in
  Darwin)
    PLATFORM="mac"
    ok "macOS detected"
    ;;
  Linux)
    PLATFORM="linux"
    ok "Linux detected"
    ;;
  *)
    err "Unsupported OS: $OS. Use macOS or Linux."
    ;;
esac

# ─── STEP 2: Prerequisite checks ─────────────────────────────────────────────
log "Checking required local tools..."
require_cmd curl
require_cmd git
require_cmd python3

python3 - <<'PY' || err "Python 3.11+ is required."
import sys
raise SystemExit(0 if sys.version_info >= (3, 11) else 1)
PY
ok "Python version OK: $(python3 --version)"

if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
  err "Node.js 18+ and npm are required for the RyanYang1390 UI repo. Install Node.js first, then rerun this script."
fi

NODE_MAJOR="$(node -v | sed 's/^v//' | cut -d. -f1)"
if [ "$NODE_MAJOR" -lt 18 ]; then
  err "Node.js 18+ is required. Current version: $(node -v)"
fi
ok "Node.js detected: $(node -v); npm detected: $(npm -v)"

# ─── STEP 3: Install Ollama ──────────────────────────────────────────────────
log "Checking for Ollama..."
if command -v ollama >/dev/null 2>&1; then
  ok "Ollama already installed: $(ollama --version)"
else
  log "Installing Ollama..."
  if [ "$PLATFORM" = "mac" ]; then
    if command -v brew >/dev/null 2>&1; then
      brew install ollama
    else
      curl -fsSL https://ollama.com/install.sh | sh
    fi
  else
    curl -fsSL https://ollama.com/install.sh | sh
  fi
  ok "Ollama installed: $(ollama --version)"
fi

# ─── STEP 4: Start Ollama server ─────────────────────────────────────────────
log "Starting Ollama server on port $OLLAMA_PORT..."
if pgrep -x "ollama" >/dev/null 2>&1; then
  ok "Ollama server already running"
else
  ollama serve > "$LOG_DIR/ollama.log" 2>&1 &
  sleep 3
  ok "Ollama server started (PID $!)"
fi

# ─── STEP 5: Pull Llama 3.2 model ────────────────────────────────────────────
log "Pulling $LLAMA_MODEL — this may take a few minutes on first run..."
ollama pull "$LLAMA_MODEL"
ok "$LLAMA_MODEL ready"

# ─── STEP 6: Verify Llama model ──────────────────────────────────────────────
log "Running a quick test inference to verify the model..."
TEST_RESPONSE="$(ollama run "$LLAMA_MODEL" "Respond with exactly: OK" 2>/dev/null | head -1 || true)"
ok "Model response: ${TEST_RESPONSE:-<no output captured>}"

# ─── STEP 7: Main Python virtual environment ─────────────────────────────────
log "Setting up Python virtual environment for the FastAPI expert module..."
if [ ! -d "$VENV_DIR" ]; then
  python3 -m venv "$VENV_DIR"
  ok "Virtual environment created at $VENV_DIR"
else
  ok "Virtual environment already exists at $VENV_DIR"
fi

log "Installing Python dependencies for the FastAPI expert module..."
"$VENV_DIR/bin/python" -m pip install --upgrade pip -q
"$VENV_DIR/bin/python" -m pip install fastapi uvicorn httpx python-dotenv pydantic requests pyyaml -q
ok "FastAPI expert module dependencies installed"

# ─── STEP 8: Clone / update additional systems ───────────────────────────────
log "Setting up additional UNICC systems..."
clone_or_update_repo "$RYAN_REPO" "$RYAN_DIR"
clone_or_update_repo "$AGENT_REPO" "$AGENT_DIR"

# ─── STEP 9: Setup RyanYang1390/unicc-ai-safety-sandbox-final ───────────────
log "Installing Node dependencies for UNICC AI Safety Governance Platform..."
(
  cd "$RYAN_DIR"
  npm install --no-fund --no-audit
)
ok "RyanYang1390 UI dependencies installed"

cat > "$RYAN_DIR/.env.local.example" <<'EOF'
VITE_GEMINI_API_KEY=your_gemini_api_key_here
EOF

if [ ! -f "$RYAN_DIR/.env.local" ]; then
  cp "$RYAN_DIR/.env.local.example" "$RYAN_DIR/.env.local"
  warn "Created $RYAN_DIR/.env.local — add your Gemini API key before starting the UI."
else
  ok "Existing .env.local found for RyanYang1390 UI"
fi

# ─── STEP 10: Setup hg3016-guo/unicc-ai-agent ────────────────────────────────
log "Setting up Python virtual environment for UNICC AI Agent..."
if [ ! -d "$AGENT_VENV_DIR" ]; then
  python3 -m venv "$AGENT_VENV_DIR"
  ok "Agent virtual environment created at $AGENT_VENV_DIR"
else
  ok "Agent virtual environment already exists"
fi

log "Installing Python dependencies for UNICC AI Agent..."
"$AGENT_VENV_DIR/bin/python" -m pip install --upgrade pip -q
"$AGENT_VENV_DIR/bin/python" -m pip install inspect-ai streamlit python-dotenv reportlab -q
ok "UNICC AI Agent dependencies installed"

log "Running dependency smoke test for UNICC AI Agent..."
"$AGENT_VENV_DIR/bin/python" - <<PY
import sys
from pathlib import Path
sys.path.insert(0, str(Path(r"$AGENT_DIR") / "src"))
import inspect_ai
import streamlit
import dotenv
import reportlab
import petri
print("OK")
PY
ok "UNICC AI Agent smoke test passed"

cat > "$AGENT_DIR/.env.example" <<'EOF'
ANTHROPIC_API_KEY=your_anthropic_api_key_here
OPENAI_API_KEY=your_openai_api_key_here
EOF

if [ ! -f "$AGENT_DIR/.env" ]; then
  cp "$AGENT_DIR/.env.example" "$AGENT_DIR/.env"
  warn "Created $AGENT_DIR/.env — add your Anthropic/OpenAI API key(s) before starting the agent."
else
  ok "Existing .env found for UNICC AI Agent"
fi

# ─── STEP 11: Create helper launch scripts ───────────────────────────────────
log "Creating helper launch scripts..."

cat > "$INTEGRATIONS_DIR/run_unicc_sandbox_ui.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
cd "$RYAN_DIR"
npm run dev -- --host 0.0.0.0 --port $RYAN_UI_PORT
EOF
chmod +x "$INTEGRATIONS_DIR/run_unicc_sandbox_ui.sh"

cat > "$INTEGRATIONS_DIR/run_unicc_agent.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
source "$AGENT_VENV_DIR/bin/activate"
cd "$AGENT_DIR"
streamlit run appz.py --server.address 0.0.0.0 --server.port $AGENT_UI_PORT
EOF
chmod +x "$INTEGRATIONS_DIR/run_unicc_agent.sh"

ok "Helper launch scripts created"

# ─── STEP 12: Print summary ──────────────────────────────────────────────────
echo ""
echo -e "${GREEN}══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   SETUP COMPLETE – UNICC AI Safety Lab + Additional Systems Ready   ${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  Llama Model:           ${BLUE}$LLAMA_MODEL${NC}"
echo -e "  Ollama API:            ${BLUE}http://localhost:$OLLAMA_PORT${NC}"
echo -e "  Module API:            ${BLUE}http://localhost:$API_PORT${NC}  (start with run_module.sh)"
echo ""
echo -e "  RyanYang1390 UI Repo:  ${BLUE}$RYAN_DIR${NC}"
echo -e "  Ryan UI URL:           ${BLUE}http://localhost:$RYAN_UI_PORT${NC}"
echo -e "  Ryan Env File:         ${BLUE}$RYAN_DIR/.env.local${NC}"
echo -e "  Ryan Start Script:     ${BLUE}$INTEGRATIONS_DIR/run_unicc_sandbox_ui.sh${NC}"
echo ""
echo -e "  UNICC AI Agent Repo:   ${BLUE}$AGENT_DIR${NC}"
echo -e "  Agent UI URL:          ${BLUE}http://localhost:$AGENT_UI_PORT${NC}"
echo -e "  Agent Env File:        ${BLUE}$AGENT_DIR/.env${NC}"
echo -e "  Agent Start Script:    ${BLUE}$INTEGRATIONS_DIR/run_unicc_agent.sh${NC}"
echo ""
echo -e "  Logs:                  ${BLUE}$LOG_DIR/${NC}"
echo ""
echo -e "  NEXT STEPS:"
echo -e "  1. Edit ${YELLOW}$RYAN_DIR/.env.local${NC} and add ${YELLOW}VITE_GEMINI_API_KEY${NC}"
echo -e "  2. Edit ${YELLOW}$AGENT_DIR/.env${NC} and add ${YELLOW}ANTHROPIC_API_KEY${NC} and/or ${YELLOW}OPENAI_API_KEY${NC}"
echo -e "  3. Run ${YELLOW}$INTEGRATIONS_DIR/run_unicc_sandbox_ui.sh${NC}"
echo -e "  4. Run ${YELLOW}$INTEGRATIONS_DIR/run_unicc_agent.sh${NC}"
echo -e "  5. Run ${YELLOW}./run_all.sh${NC} to start all services together"
echo ""
