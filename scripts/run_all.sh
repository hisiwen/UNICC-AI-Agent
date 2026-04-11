#!/usr/bin/env bash
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
