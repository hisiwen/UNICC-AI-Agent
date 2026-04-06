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
