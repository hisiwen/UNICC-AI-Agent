from pathlib import Path
from typing import Any, Dict, List

import requests
import yaml
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from agents.schemas import EvaluateRequest


def load_yaml(path: str) -> Dict[str, Any]:
    with open(path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


ROOT_DIR = Path(__file__).resolve().parents[1]
CONFIG_PATH = ROOT_DIR / "configs" / "orchestrator.yaml"
CONFIG = load_yaml(str(CONFIG_PATH))
AGENTS = CONFIG.get("agents", [])

app = FastAPI(title="AI_AGENT Orchestrator")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def dedupe_keep_order(items: List[str]) -> List[str]:
    seen = set()
    result = []
    for item in items:
        if not item:
            continue
        if item not in seen:
            seen.add(item)
            result.append(item)
    return result


def normalize_to_string_list(value: Any, preferred_key: str = "") -> List[str]:
    if not value:
        return []

    result = []

    if isinstance(value, list):
        for item in value:
            if isinstance(item, str):
                text = item.strip()
                if text:
                    result.append(text)
            elif isinstance(item, dict):
                if preferred_key and item.get(preferred_key):
                    text = str(item[preferred_key]).strip()
                    if text:
                        result.append(text)
                else:
                    for v in item.values():
                        if isinstance(v, str) and v.strip():
                            result.append(v.strip())
                            break

    elif isinstance(value, str):
        text = value.strip()
        if text:
            result.append(text)

    return dedupe_keep_order(result)


def extract_recommendation(parsed: Dict[str, Any]) -> str:
    if not isinstance(parsed, dict):
        return "Unknown"
    rec = parsed.get("recommendation", "Unknown")
    if isinstance(rec, str):
        return rec.strip()
    return "Unknown"


def normalize_agent_result(result: Dict[str, Any]) -> Dict[str, Any]:
    parsed = result.get("parsed")

    if not isinstance(parsed, dict):
        return result

    agent_id = result.get("agent_id", "")

    if agent_id == "safety_dimensions_agent":
        parsed["high_priority_risks"] = normalize_to_string_list(
            parsed.get("high_priority_risks"),
            preferred_key="dimension",
        )
        parsed["mitigations"] = normalize_to_string_list(
            parsed.get("mitigations"),
            preferred_key="mitigation",
        )

    if agent_id == "standards_compliance_agent":
        parsed["key_gaps"] = normalize_to_string_list(parsed.get("key_gaps"))
        parsed["required_controls"] = normalize_to_string_list(parsed.get("required_controls"))

    if agent_id == "assurance_accountability_agent":
        parsed["evidence_gaps"] = normalize_to_string_list(parsed.get("evidence_gaps"))
        parsed["assurance_controls"] = normalize_to_string_list(parsed.get("assurance_controls"))
        parsed["accountability_structure"] = normalize_to_string_list(parsed.get("accountability_structure"))

    result["parsed"] = parsed
    return result


def build_summary(agent_results: List[Dict[str, Any]]) -> Dict[str, Any]:
    cross_agent_gaps: List[str] = []
    cross_agent_controls: List[str] = []
    cross_agent_risks: List[str] = []

    for result in agent_results:
        parsed = result.get("parsed")
        if not isinstance(parsed, dict):
            continue

        agent_id = result.get("agent_id", "")

        if agent_id == "standards_compliance_agent":
            cross_agent_gaps.extend(normalize_to_string_list(parsed.get("key_gaps")))
            cross_agent_controls.extend(normalize_to_string_list(parsed.get("required_controls")))

        elif agent_id == "safety_dimensions_agent":
            cross_agent_risks.extend(normalize_to_string_list(parsed.get("high_priority_risks")))
            cross_agent_controls.extend(
                normalize_to_string_list(parsed.get("mitigations"), preferred_key="mitigation")
            )

        elif agent_id == "assurance_accountability_agent":
            cross_agent_gaps.extend(normalize_to_string_list(parsed.get("evidence_gaps")))
            cross_agent_controls.extend(normalize_to_string_list(parsed.get("assurance_controls")))

    return {
        "cross_agent_risks": dedupe_keep_order(cross_agent_risks),
        "cross_agent_gaps": dedupe_keep_order(cross_agent_gaps),
        "cross_agent_controls": dedupe_keep_order(cross_agent_controls),
    }


def aggregate_final_decision(agent_results: List[Dict[str, Any]]) -> str:
    recommendations = []

    for result in agent_results:
        parsed = result.get("parsed")
        recommendations.append(extract_recommendation(parsed))

    recs = [r.lower() for r in recommendations]

    reject_count = sum("reject" in r for r in recs)
    flag_count = sum("flag" in r for r in recs)
    conditional_count = sum("approve with conditions" in r for r in recs)
    approve_count = sum(r == "approve" for r in recs)

    if reject_count >= 1:
        return "Reject"
    if flag_count >= 1:
        return "Flag for Review"
    if conditional_count >= 1:
        return "Approve with Conditions"
    if approve_count == len(recommendations) and approve_count > 0:
        return "Approve"

    return "Approve with Conditions"


@app.get("/health")
def health() -> Dict[str, Any]:
    health_results = []

    for agent in AGENTS:
        agent_id = agent.get("agent_id", "unknown")
        health_url = agent.get("health_url")
        if not health_url:
            base_url = agent["url"].replace("/evaluate", "")
            health_url = f"{base_url}/health"

        try:
            res = requests.get(health_url, timeout=15)
            res.raise_for_status()
            health_results.append(
                {
                    "agent_id": agent_id,
                    "health": res.json(),
                }
            )
        except Exception as e:
            health_results.append(
                {
                    "agent_id": agent_id,
                    "health": {
                        "status": "error",
                        "detail": str(e),
                    },
                }
            )

    return {
        "status": "ok",
        "name": "AI_AGENT Orchestrator",
        "agents": health_results,
    }


@app.post("/run")
def run(payload: EvaluateRequest) -> Dict[str, Any]:
    agent_results = []

    for agent in AGENTS:
        agent_id = agent.get("agent_id", "unknown")
        url = agent["url"]

        try:
            res = requests.post(url, json=payload.model_dump(), timeout=120)
            res.raise_for_status()
            result = res.json()
            result = normalize_agent_result(result)
            agent_results.append(result)
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to call {agent_id}: {e}",
            ) from e

    summary = build_summary(agent_results)
    final_decision = aggregate_final_decision(agent_results)

    return {
        "system": "AI_AGENT Orchestrator",
        "final_decision": final_decision,
        "summary": summary,
        "agent_results": agent_results,
    }