#!/usr/bin/env bash
# =============================================================================
# UNICC AI Safety Lab – Ollama + Llama 3.2 Setup Script
# Pillar 1: Research & Platform Preparation
# Author: Siwen Shen | NYU MASY GC-4100
# =============================================================================
# Run this script once on your local machine (Mac/Linux) to:
#   1. Install Ollama
#   2. Pull Llama 3.2 (8B) model weights
#   3. Start the Ollama API server
#   4. Install Python dependencies for the FastAPI expert module
#   5. Verify everything is working
#
# Usage:
#   chmod +x setup.sh
#   ./setup.sh
# =============================================================================

set -e  # Exit on any error

LLAMA_MODEL="llama3.2:8b"  # Change to llama3.2:3b if low on RAM (<16GB)
OLLAMA_PORT=11434
API_PORT=8000
LOG_DIR="../logs"
VENV_DIR="../.venv"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${BLUE}[SETUP]${NC} $1"; }
ok()   { echo -e "${GREEN}[OK]${NC}    $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $1"; }
err()  { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

mkdir -p "$LOG_DIR"
log "Log directory ready at $LOG_DIR"

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

# ─── STEP 2: Install Ollama ──────────────────────────────────────────────────
log "Checking for Ollama..."
if command -v ollama &>/dev/null; then
  ok "Ollama already installed: $(ollama --version)"
else
  log "Installing Ollama..."
  if [ "$PLATFORM" = "mac" ]; then
    if command -v brew &>/dev/null; then
      brew install ollama
    else
      warn "Homebrew not found. Downloading Ollama installer..."
      curl -fsSL https://ollama.com/install.sh | sh
    fi
  else
    curl -fsSL https://ollama.com/install.sh | sh
  fi
  ok "Ollama installed: $(ollama --version)"
fi

# ─── STEP 3: Start Ollama server ─────────────────────────────────────────────
log "Starting Ollama server on port $OLLAMA_PORT..."
if pgrep -x "ollama" > /dev/null; then
  ok "Ollama server already running"
else
  if [ "$PLATFORM" = "mac" ]; then
    ollama serve > "$LOG_DIR/ollama.log" 2>&1 &
  else
    ollama serve > "$LOG_DIR/ollama.log" 2>&1 &
  fi
  sleep 3
  ok "Ollama server started (PID $!)"
fi

# ─── STEP 4: Pull Llama 3.2 model ────────────────────────────────────────────
log "Pulling $LLAMA_MODEL — this may take a few minutes on first run..."
ollama pull "$LLAMA_MODEL"
ok "$LLAMA_MODEL ready"

# ─── STEP 5: Verify model runs ───────────────────────────────────────────────
log "Running a quick test inference to verify the model..."
TEST_RESPONSE=$(ollama run "$LLAMA_MODEL" "Respond with exactly: OK" 2>/dev/null | head -1)
ok "Model response: $TEST_RESPONSE"

# ─── STEP 6: Python virtual environment ──────────────────────────────────────
log "Setting up Python virtual environment..."
if [ ! -d "$VENV_DIR" ]; then
  python3 -m venv "$VENV_DIR"
  ok "Virtual environment created at $VENV_DIR"
else
  ok "Virtual environment already exists"
fi

source "$VENV_DIR/bin/activate"
log "Installing Python dependencies..."
pip install --upgrade pip -q
pip install fastapi uvicorn httpx python-dotenv pydantic requests -q
ok "Python dependencies installed"

# ─── STEP 7: Print summary ───────────────────────────────────────────────────
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  SETUP COMPLETE – UNICC AI Safety Lab Platform Ready   ${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  Model:          ${BLUE}$LLAMA_MODEL${NC}"
echo -e "  Ollama API:     ${BLUE}http://localhost:$OLLAMA_PORT${NC}"
echo -e "  Module API:     ${BLUE}http://localhost:$API_PORT${NC}  (start with run_module.sh)"
echo -e "  Logs:           ${BLUE}$LOG_DIR/${NC}"
echo ""
echo -e "  NEXT STEPS:"
echo -e "  1. ${YELLOW}./run_module.sh${NC}       — Start the FastAPI Expert Module"
echo -e "  2. ${YELLOW}python benchmark.py${NC}   — Run baseline benchmark (FR-3.2)"
echo -e "  3. ${YELLOW}python test_api.py${NC}    — Test the module API"
echo ""
