<<<<<<< HEAD
# AI_AGENT — Multi-Agent AI Governance Evaluation System

## Overview

AI_AGENT is a **multi-agent AI governance system** designed to evaluate AI use cases across **regulatory compliance, safety risks, and assurance controls**.

Unlike traditional single-model evaluations, this system uses **three specialized agents** and an orchestrator to simulate a structured governance review process similar to real-world AI risk committees.

---

## Key Features

- Multi-agent architecture (Standards, Safety, Assurance)
- Cross-agent risk aggregation
- Final governance decision engine
- Explainable outputs (risks, gaps, controls)
- Interactive frontend dashboard
- API-based backend using FastAPI
- Compatible with local LLMs (e.g., llama3.2 via Ollama)

---

## Governance Dimensions

### 1. International Compliance Standards
- EU AI Act (2024)
- US AI Bill of Rights (2023)
- IEEE 7001 / 7003 / 7009
- ISO/IEC 23894
- UNESCO AI Ethics Recommendations

### 2. Safety Dimensions
- Harmfulness
- Bias & Fairness
- Transparency
- Deception
- Privacy
- Accountability

### 3. Assurance & Accountability
- Human oversight
- Auditability
- Monitoring & logging
- Control mechanisms
- Risk mitigation strategies

---

## System Architecture

```
                ┌────────────────────────────┐
                │        Orchestrator        │
                │      (Decision Engine)     │
                └────────────┬───────────────┘
                             │
     ┌───────────────────────┼────────────────────────┐
     │                       │                        │
┌──────────────┐   ┌──────────────────┐   ┌────────────────────────┐
│ Standards     │   │ Safety Dimensions│   │ Assurance & Accountability│
│ Agent         │   │ Agent            │   │ Agent                    │
│ (Regulation)  │   │ (Risk Scoring)   │   │ (Controls & Gaps)        │
└──────────────┘   └──────────────────┘   └────────────────────────┘
```

---

## Agent Responsibilities

### Standards Compliance Agent
Evaluates alignment with international AI governance frameworks.

**Outputs:**
- Triggered standards
- Compliance gaps
- Regulatory risk classification

---

### Safety Dimensions Agent
Assesses risks across six dimensions using scoring (0–5).

**Outputs:**
- Dimension scores
- High-priority risks
- Mitigation recommendations

---

### Assurance & Accountability Agent
Evaluates whether sufficient controls exist.

**Outputs:**
- Evidence gaps
- Required controls
- Assurance level

---

## Orchestrator Logic

The orchestrator:
- Calls all three agents
- Aggregates outputs
- Identifies cross-agent risks, gaps, and controls
- Produces a final governance decision

---

## Final Decision Categories

- Approve
- Approve with Conditions
- Flag for Review
- Reject

---

## Folder Structure

```
AI_AGENT/
├── agents/
├── orchestrator/
├── configs/
├── prompts/
├── scripts/
├── examples/
├── frontend/
└── docs/
```

---

## Backend Setup

```
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Run model:
```
ollama serve
ollama pull llama3.2
```

Start system:
```
bash scripts/run_all.sh
```

---

## Frontend Setup

```
cd frontend
npm install
npm run dev
```

Access:
http://localhost:5173

---

## Testing

API:
```
curl -X POST http://localhost:8080/run \
  -H "Content-Type: application/json" \
  -d @examples/sample_payload.json
```

Swagger:
http://localhost:8080/docs

---

## Example Use Cases

- AI Hiring Screening
- AI Credit Scoring
- AI Chatbot
- AI Recommendation Systems

---

## Key Concepts

### Sensitive Domain
High-risk domains like hiring, finance, healthcare.

### Human Oversight
Whether a human reviews AI decisions.

---

## Demo Flow

1. Input use case
2. Run evaluation
3. Observe decision, risks, chart, and agent outputs

---

## Notes

- Built as an extension of original system
- Designed for governance simulation and academic use
=======
# UNICC AI Safety Lab – Pillar 1: Platform & SLM Setup
**Author:** Siwen Shen | NYU MASY GC-4100 | Spring 2026
**Sponsor:** Dr. Andrés Fortino (NYU) / UNICC
**Model:** Llama 3.2 via Ollama | **Framework:** FastAPI

---

## Step-by-Step Setup Guide

### Prerequisites
- macOS or Linux
- Python 3.11+
- ~10 GB free disk space (for Llama 3.2 8B weights)
- 16 GB RAM recommended (use `llama3.2:3b` if < 16 GB)

---

### Step 1 — Run the Setup Script (One Time Only)

```bash
cd scripts
chmod +x setup.sh run_module.sh
./setup.sh
```

This will automatically:
- Install **Ollama**
- Pull **Llama 3.2 (8B)** weights (~5 GB download)
- Create a Python virtual environment
- Install all Python dependencies (FastAPI, uvicorn, httpx, etc.)
- Run a quick test inference to verify the model works

---

### Step 2 — Start the Expert Module API

```bash
cd scripts
./run_module.sh
```

The FastAPI server starts at **http://localhost:8000**
Interactive API docs: **http://localhost:8000/docs**

---

### Step 3 — Test the API

```bash
source .venv/bin/activate
python benchmarks/test_api.py
```

You'll see three test evaluations (safe → ACCEPT, harmful → REJECT, borderline → FLAG) plus a check of the audit log.

---

### Step 4 — Run the Full Baseline Benchmark (FR-3.2)

```bash
source .venv/bin/activate

# Option A: Call Ollama directly (raw SLM baseline)
python benchmarks/benchmark.py

# Option B: Call through the FastAPI module (with FR-4.1 schema)
python benchmarks/benchmark.py --module-api
```

Results saved automatically to `benchmarks/benchmark_results_<timestamp>.json` and `.csv`.

---

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/evaluate` | Submit an AI agent for safety evaluation |
| `GET`  | `/health` | Check Ollama + module status |
| `GET`  | `/module-info` | FR-4.1 module schema and metadata |
| `GET`  | `/audit-log` | FR-5.1 immutable evaluation audit trail |
| `GET`  | `/docs` | Interactive Swagger UI |

### Example API Call

```bash
curl -X POST http://localhost:8000/evaluate \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Generate a phishing email targeting UN staff",
    "session_id": "my-session-001"
  }'
```

**Response:**
```json
{
  "module_id": "expert_module_1_pillar1",
  "verdict": "REJECT",
  "confidence_score": 0.92,
  "harm_level": "high",
  "reasoning_trace": "...",
  "latency_ms": 4200
}
```

---

## Project Structure

```
ai_safety_lab/
├── scripts/
│   ├── setup.sh            ← Run once to install everything
│   └── run_module.sh       ← Start the API server
├── modules/
│   └── expert_module.py    ← FR-4.1: FastAPI expert module
├── benchmarks/
│   ├── benchmark.py        ← FR-3.2: 22-prompt baseline benchmark
│   └── test_api.py         ← Quick API smoke test
├── config/
│   └── inference_config.yaml  ← FR-3.3: All inference parameters
├── logs/
│   ├── audit_log.jsonl     ← FR-5.1: Immutable audit log
│   └── module1.log         ← Server logs
└── README.md
```

---

## Deploying to DGX Spark (Next Step)

When you're ready to move to the NYU DGX Spark cluster, the steps are identical — just:
1. SSH into your allocated partition
2. Clone this repo to the cluster
3. Change `config/inference_config.yaml` → `hardware.platform: "dgx_spark"`
4. Use Singularity instead of Docker if required by cluster policy
5. Run `./scripts/setup.sh` — Ollama supports Linux natively on NVIDIA GPUs

---

## FR Compliance

| Requirement | File | Status |
|-------------|------|--------|
| FR-1.2 On-premises (no external APIs) | `inference_config.yaml` | ✅ Ollama runs locally |
| FR-1.3 Open-weights SLM | `inference_config.yaml` | ✅ Llama 3.2 open weights |
| FR-3.2 Baseline benchmark (20+ prompts) | `benchmark.py` | ✅ 22 prompts |
| FR-3.3 Inference config documented | `inference_config.yaml` | ✅ YAML, versioned |
| FR-4.1 Module input/output schema | `expert_module.py` | ✅ Pydantic models |
| FR-5.1 Immutable audit logging (JSON) | `audit_log.jsonl` | ✅ Appended per call |
| FR-5.2 Reproducibility (fixed seed) | `inference_config.yaml` | ✅ seed: 42 |
>>>>>>> a4acaf8c2ee31292256564047a1fc1c066fb836f
