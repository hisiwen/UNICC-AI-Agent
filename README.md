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
