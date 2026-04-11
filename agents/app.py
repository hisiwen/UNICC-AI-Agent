import json
import os
from pathlib import Path
from typing import Any, Dict, Optional

import yaml
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from agents.llm import generate_json_response
from agents.schemas import EvaluateRequest


def load_yaml(path: str) -> Dict[str, Any]:
    with open(path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def load_text(path: str) -> str:
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


ROOT_DIR = Path(__file__).resolve().parents[1]
CONFIG_ENV = os.getenv("AGENT_CONFIG")
if not CONFIG_ENV:
    raise RuntimeError("AGENT_CONFIG environment variable is required")

CONFIG_PATH = ROOT_DIR / CONFIG_ENV
CONFIG = load_yaml(str(CONFIG_PATH))
PROMPT_PATH = ROOT_DIR / CONFIG["prompt"]["system_file"]
SYSTEM_PROMPT = load_text(str(PROMPT_PATH))

AGENT_ID = CONFIG["agent"]["id"]
AGENT_NAME = CONFIG["agent"]["name"]
MODEL = CONFIG["agent"]["model"]

app = FastAPI(title=AGENT_NAME)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def build_prompt(payload: EvaluateRequest) -> str:
    return (
        f"{SYSTEM_PROMPT}\n\n"
        f"Use case title: {payload.use_case_title}\n"
        f"Description: {payload.description}\n"
        f"Intended users: {payload.intended_users or 'Not provided'}\n"
        f"Affected groups: {payload.affected_groups or 'Not provided'}\n"
        f"Data sources: {payload.data_sources or 'Not provided'}\n"
        f"Deployment context: {payload.deployment_context or 'Not provided'}\n"
        f"Current controls: {payload.current_controls or 'Not provided'}\n"
        f"Extra context: {json.dumps(payload.extra_context or {}, ensure_ascii=False)}\n"
    )


def try_parse_json(text: str) -> Optional[Dict[str, Any]]:
    text = text.strip()

    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass

    if text.startswith("```"):
        lines = text.splitlines()
        if len(lines) >= 3:
            stripped = "\n".join(lines[1:-1]).strip()
            try:
                return json.loads(stripped)
            except json.JSONDecodeError:
                pass

    start = text.find("{")
    end = text.rfind("}")
    if start != -1 and end != -1 and end > start:
        snippet = text[start : end + 1]
        try:
            return json.loads(snippet)
        except json.JSONDecodeError:
            return None

    return None


def normalize_safety_dimensions_output(parsed: Dict[str, Any]) -> Dict[str, Any]:
    dimension_scores = parsed.get("dimension_scores", [])
    normalized_scores = []

    for item in dimension_scores:
        if not isinstance(item, dict):
            continue

        dimension = item.get("dimension")
        score = item.get("score", 0)
        reasoning = item.get("reasoning", "")

        if isinstance(dimension, str):
            normalized_scores.append(
                {
                    "dimension": dimension,
                    "score": score,
                    "reasoning": reasoning,
                }
            )

    parsed["dimension_scores"] = normalized_scores

    parsed["high_priority_risks"] = [
        item["dimension"]
        for item in normalized_scores
        if isinstance(item.get("score"), (int, float)) and item["score"] >= 4
    ]

    if not parsed.get("mitigations"):
        parsed["mitigations"] = [
            "Implement a diverse and representative dataset for training and retraining.",
            "Add regular bias and fairness audits with documented review checkpoints.",
            "Strengthen privacy protections and limit access to sensitive applicant data.",
            "Require human review for high-impact or borderline hiring decisions.",
        ]

    return parsed


def normalize_agent_output(agent_id: str, parsed: Optional[Dict[str, Any]]) -> Optional[Dict[str, Any]]:
    if not isinstance(parsed, dict):
        return parsed

    if agent_id == "safety_dimensions_agent":
        return normalize_safety_dimensions_output(parsed)

    return parsed


@app.get("/health")
def health() -> Dict[str, Any]:
    return {
        "status": "ok",
        "agent_id": AGENT_ID,
        "agent_name": AGENT_NAME,
        "model": MODEL,
    }


@app.post("/evaluate")
def evaluate(payload: EvaluateRequest) -> Dict[str, Any]:
    prompt = build_prompt(payload)

    try:
        raw = generate_json_response(MODEL, prompt)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"LLM call failed: {e}") from e

    parsed = try_parse_json(raw)
    parsed = normalize_agent_output(AGENT_ID, parsed)

    return {
        "agent_id": AGENT_ID,
        "agent_name": AGENT_NAME,
        "raw_text": raw,
        "parsed": parsed,
    }