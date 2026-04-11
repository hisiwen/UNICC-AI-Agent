#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
export AGENT_CONFIG="configs/safety_dimensions_agent.yaml"
uvicorn agents.app:app --host 0.0.0.0 --port 8001 --reload
