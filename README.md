# AI_AGENT — Multi-Agent AI Governance Evaluation System

## Overview

AI_AGENT is a multi-agent AI governance system designed to evaluate AI use cases across regulatory compliance, safety risks, and assurance controls.

Unlike traditional single-model evaluations, this system uses three specialized agents and an orchestrator to simulate a structured governance review process similar to real-world AI risk committees.

## Key Features

- Multi-agent architecture (Standards, Safety, Assurance)
- Cross-agent risk aggregation
- Final governance decision engine
- Explainable outputs (risks, gaps, controls)
- Interactive frontend dashboard
- API-based backend using FastAPI
- Compatible with local LLMs (e.g., llama3.2 via Ollama)

## System Architecture
┌────────────────────────────┐
│        Orchestrator        │
│      (Decision Engine)     │
└────────────┬───────────────┘
│
┌────────────┼────────────────┐
│            │                │
Standards   Safety        Assurance
Agent       Agent         Agent
## Backend Setup

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
ollama serve
ollama pull llama3.2
bash scripts/run_all.sh
```

## Frontend Setup

```bash
cd frontend
npm install
npm run dev
```

Access: http://localhost:5173  
Swagger: http://localhost:8080/docs

## Author

Siwen Shen | NYU MASY GC-4100 | Spring 2026  
Sponsor: Dr. Andrés Fortino (NYU) / UNICC
