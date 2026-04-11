# AI_AGENT — Multi-Agent AI Governance Evaluation System

## Overview

AI_AGENT is a multi-agent AI governance system that evaluates AI use cases across:

- Regulatory compliance (international standards)
- Safety risks (bias, privacy, harm, transparency)
- Assurance & accountability (controls, oversight, auditability)

The system simulates a real-world AI governance review process using multiple specialized agents and an orchestrator.

---

## Key Features

- Multi-agent architecture (Standards, Safety, Assurance)
- Cross-agent risk aggregation
- Final governance decision engine
- Explainable outputs (risks, gaps, controls)
- Interactive React dashboard
- FastAPI backend
- Local LLM support (llama3.2 via Ollama)

---

## Architecture

Standards Agent → Compliance  
Safety Agent → Risk Scoring  
Assurance Agent → Controls  

→ Orchestrator → Final Decision

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

## Governance Dimensions

### Standards
- EU AI Act (2024)
- US AI Bill of Rights (2023)
- IEEE 7001 / 7003 / 7009
- ISO/IEC 23894
- UNESCO AI Ethics Recommendations

### Safety
- Harmfulness
- Bias & Fairness
- Transparency
- Deception
- Privacy
- Accountability

### Assurance
- Human oversight
- Auditability
- Monitoring & logging
- Risk control mechanisms

---

## Final Decision Categories

- Approve
- Approve with Conditions
- Flag for Review
- Reject

---

## Folder Structure

AI_AGENT/
├── agents/  
├── orchestrator/  
├── configs/  
├── prompts/  
├── scripts/  
├── examples/  
├── frontend/  
├── docs/  
└── README.md  

---

## Backend Setup

python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

ollama serve
ollama pull llama3.2

bash scripts/run_all.sh

---

## Frontend Setup

cd frontend
npm install
npm run dev

Open in browser:
http://localhost:5173

---

## Testing

curl -X POST http://localhost:8080/run \
  -H "Content-Type: application/json" \
  -d @examples/sample_payload.json

Swagger UI:
http://localhost:8080/docs

---

## Demo

Add your demo GIF here:
docs/demo.gif

---

## Example Use Cases

- AI Hiring Screening System
- AI Credit Scoring System
- AI Healthcare Assistant
- AI Recommendation System
- Customer Support Chatbot

---

## Key Concepts

Sensitive Domain: High-risk areas like hiring, finance, healthcare  
Human Oversight: Whether humans review AI decisions

---

## Notes

Designed for AI governance simulation, academic use, and demonstrating multi-agent AI system design.
