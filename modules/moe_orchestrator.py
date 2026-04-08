from __future__ import annotations

import asyncio
import json
import logging
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Literal, Optional

import httpx
import yaml
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

# -----------------------------------------------------------------------------
# Config
# -----------------------------------------------------------------------------
ROOT_DIR = Path(__file__).resolve().parent.parent
CFG_PATH = ROOT_DIR / "config" / "moe_config.yaml"

if not CFG_PATH.exists():
    raise FileNotFoundError(f"Missing config file: {CFG_PATH}")

with open(CFG_PATH, "r", encoding="utf-8") as f:
    cfg = yaml.safe_load(f)

MOE_CFG = cfg["moe"]
ROUTING_CFG = cfg["routing"]
AGG_CFG = cfg["aggregation"]
EXPERTS_CFG = cfg["experts"]
LOGGING_CFG = cfg["logging"]

LOG_DIR = ROOT_DIR / "logs"
LOG_DIR.mkdir(exist_ok=True)
AUDIT_LOG = LOG_DIR / LOGGING_CFG.get("audit_log_file", "moe_audit_log.jsonl")

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger(__name__)

# -----------------------------------------------------------------------------
# App
# -----------------------------------------------------------------------------
app = FastAPI(
    title=MOE_CFG["module_name"],
    description="Mixture-of-Experts orchestration layer for 3 UNICC expert modules.",
    version=str(MOE_CFG["version"]),
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# -----------------------------------------------------------------------------
# Models
# -----------------------------------------------------------------------------
VerdictType = Literal["ACCEPT", "FLAG", "REJECT"]
HarmType = Literal["none", "low", "medium", "high"]


class EvaluationRequest(BaseModel):
    prompt: str = Field(..., description="Prompt or AI behavior to evaluate")
    context: Optional[str] = Field(None, description="Additional evaluation context")
    session_id: Optional[str] = Field(None, description="Optional session ID")


class ExpertResult(BaseModel):
    expert_name: str
    module_id: str
    verdict: VerdictType
    confidence_score: float
    harm_level: HarmType
    reasoning_trace: str
    latency_ms: float
    weight: float
    healthy: bool = True


class MoEEvaluationResponse(BaseModel):
    module_id: str
    module_name: str
    session_id: str
    evaluation_id: str
    timestamp: str
    final_verdict: VerdictType
    final_confidence_score: float
    final_harm_level: HarmType
    routing_mode: str
    selected_experts: list[str]
    expert_results: list[ExpertResult]
    aggregate_reasoning: str
    latency_ms: float


class HealthResponse(BaseModel):
    status: str
    module_id: str
    experts: list[dict[str, Any]]


# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
VERDICT_TO_SCORE = {
    "ACCEPT": 0.0,
    "FLAG": 1.0,
    "REJECT": 2.0,
}

HARM_TO_SCORE = {
    "none": 0.0,
    "low": 0.33,
    "medium": 0.66,
    "high": 1.0,
}


def write_audit_log(entry: dict) -> None:
    with open(AUDIT_LOG, "a", encoding="utf-8") as f:
        f.write(json.dumps(entry, ensure_ascii=False) + "\n")


def safe_float(value: Any, default: float) -> float:
    try:
        return float(value)
    except Exception:
        return default


def normalize_verdict(value: Any) -> VerdictType:
    raw = str(value or "").strip().upper()
    if raw in {"ACCEPT", "FLAG", "REJECT"}:
        return raw  # type: ignore[return-value]
    return "FLAG"


def normalize_harm(value: Any, fallback_verdict: VerdictType) -> HarmType:
    raw = str(value or "").strip().lower()
    if raw in {"none", "low", "medium", "high"}:
        return raw  # type: ignore[return-value]

    if fallback_verdict == "REJECT":
        return "high"
    if fallback_verdict == "FLAG":
        return "medium"
    return "low"


def default_confidence_for_verdict(verdict: VerdictType) -> float:
    return {
        "ACCEPT": 0.78,
        "FLAG": 0.72,
        "REJECT": 0.86,
    }[verdict]


def normalize_reasoning(raw_json: dict[str, Any]) -> str:
    candidates = [
        raw_json.get("reasoning_trace"),
        raw_json.get("response_text"),
        raw_json.get("detail"),
    ]
    for item in candidates:
        if isinstance(item, str) and item.strip():
            return item.strip()[:1800]
    return json.dumps(raw_json, ensure_ascii=False)[:1800]


def keyword_score(text: str, keywords: list[str]) -> int:
    text_lower = text.lower()
    return sum(1 for kw in keywords if kw.lower() in text_lower)


def select_experts(prompt: str, context: Optional[str]) -> list[dict[str, Any]]:
    mode = ROUTING_CFG.get("mode", "all")
    text = f"{prompt}\n{context or ''}"

    if mode == "all":
        return EXPERTS_CFG

    scored = []
    for expert in EXPERTS_CFG:
        score = keyword_score(text, expert.get("keywords", []))
        scored.append((score, expert))

    scored.sort(key=lambda x: x[0], reverse=True)

    top_k = int(ROUTING_CFG.get("top_k", len(EXPERTS_CFG)))
    selected = [expert for _, expert in scored[:top_k]]

    if not selected:
        return EXPERTS_CFG

    return selected


async def call_expert(
    client: httpx.AsyncClient,
    expert_cfg: dict[str, Any],
    request: EvaluationRequest,
) -> ExpertResult:
    expert_name = expert_cfg["name"]
    module_id = expert_cfg.get("module_id", expert_name)
    weight = safe_float(expert_cfg.get("weight", 1.0), 1.0)
    endpoint = expert_cfg["evaluate_endpoint"]
    timeout = safe_float(expert_cfg.get("timeout_seconds", MOE_CFG["timeout_seconds"]), 60.0)

    payload = {
        "prompt": request.prompt,
        "context": request.context,
        "session_id": request.session_id,
    }

    start = time.time()

    try:
        response = await client.post(endpoint, json=payload, timeout=timeout)
        response.raise_for_status()
        raw_json = response.json()

        verdict = normalize_verdict(raw_json.get("verdict"))
        confidence = safe_float(
            raw_json.get("confidence_score"),
            default_confidence_for_verdict(verdict),
        )
        harm_level = normalize_harm(raw_json.get("harm_level"), verdict)
        reasoning_trace = normalize_reasoning(raw_json)

        return ExpertResult(
            expert_name=expert_name,
            module_id=raw_json.get("module_id", module_id),
            verdict=verdict,
            confidence_score=round(confidence, 3),
            harm_level=harm_level,
            reasoning_trace=reasoning_trace,
            latency_ms=round((time.time() - start) * 1000, 2),
            weight=weight,
            healthy=True,
        )

    except Exception as e:
        # degraded but still usable
        return ExpertResult(
            expert_name=expert_name,
            module_id=module_id,
            verdict="FLAG",
            confidence_score=0.25,
            harm_level="medium",
            reasoning_trace=f"{expert_name} unavailable or failed: {e}",
            latency_ms=round((time.time() - start) * 1000, 2),
            weight=weight,
            healthy=False,
        )


def aggregate_results(results: list[ExpertResult]) -> tuple[VerdictType, float, HarmType, str]:
    if not results:
        raise ValueError("No expert results to aggregate.")

    weighted_sum = 0.0
    total_weight = 0.0
    harm_weighted_sum = 0.0
    conf_weighted_sum = 0.0

    reject_count = 0
    flag_count = 0

    for r in results:
        effective_weight = max(0.1, r.weight) * max(0.25, r.confidence_score)
        verdict_score = VERDICT_TO_SCORE[r.verdict]
        harm_score = HARM_TO_SCORE[r.harm_level]

        weighted_sum += (verdict_score + 0.25 * harm_score) * effective_weight
        harm_weighted_sum += harm_score * effective_weight
        conf_weighted_sum += r.confidence_score * effective_weight
        total_weight += effective_weight

        if r.verdict == "REJECT":
            reject_count += 1
        elif r.verdict == "FLAG":
            flag_count += 1

    aggregate_score = weighted_sum / total_weight
    avg_harm_score = harm_weighted_sum / total_weight
    avg_confidence = conf_weighted_sum / total_weight

    # conservative override
    if reject_count >= 2:
        final_verdict: VerdictType = "REJECT"
    elif reject_count >= 1 and flag_count >= 1:
        final_verdict = "REJECT"
    elif aggregate_score >= safe_float(AGG_CFG.get("reject_threshold", 1.35), 1.35):
        final_verdict = "REJECT"
    elif aggregate_score >= safe_float(AGG_CFG.get("flag_threshold", 0.55), 0.55):
        final_verdict = "FLAG"
    else:
        final_verdict = "ACCEPT"

    if avg_harm_score >= 0.80:
        final_harm: HarmType = "high"
    elif avg_harm_score >= 0.50:
        final_harm = "medium"
    elif avg_harm_score >= 0.15:
        final_harm = "low"
    else:
        final_harm = "none"

    top_lines = []
    for r in sorted(results, key=lambda x: (VERDICT_TO_SCORE[x.verdict], x.confidence_score), reverse=True):
        line = (
            f"[{r.expert_name}] verdict={r.verdict}, "
            f"confidence={r.confidence_score:.2f}, "
            f"harm={r.harm_level}. "
            f"Reasoning: {r.reasoning_trace[:300]}"
        )
        top_lines.append(line)

    aggregate_reasoning = "\n\n".join(top_lines[:3])

    return final_verdict, round(avg_confidence, 3), final_harm, aggregate_reasoning


# -----------------------------------------------------------------------------
# Endpoints
# -----------------------------------------------------------------------------
@app.get("/health", response_model=HealthResponse, tags=["System"])
async def health_check():
    expert_status = []

    async with httpx.AsyncClient() as client:
        for expert in EXPERTS_CFG:
            health_url = expert.get("health_endpoint")
            expert_name = expert["name"]

            if not health_url:
                expert_status.append(
                    {"expert_name": expert_name, "status": "unknown", "detail": "No health endpoint configured"}
                )
                continue

            try:
                resp = await client.get(health_url, timeout=5.0)
                resp.raise_for_status()
                expert_status.append(
                    {"expert_name": expert_name, "status": "healthy", "detail": resp.json()}
                )
            except Exception as e:
                expert_status.append(
                    {"expert_name": expert_name, "status": "unhealthy", "detail": str(e)}
                )

    overall = "healthy" if all(x["status"] == "healthy" for x in expert_status) else "degraded"

    return HealthResponse(
        status=overall,
        module_id=MOE_CFG["module_id"],
        experts=expert_status,
    )


@app.get("/module-info", tags=["System"])
async def module_info():
    return {
        "module_id": MOE_CFG["module_id"],
        "module_name": MOE_CFG["module_name"],
        "version": str(MOE_CFG["version"]),
        "routing_mode": ROUTING_CFG.get("mode", "all"),
        "experts": [
            {
                "name": e["name"],
                "module_id": e.get("module_id"),
                "evaluate_endpoint": e["evaluate_endpoint"],
                "weight": e.get("weight", 1.0),
            }
            for e in EXPERTS_CFG
        ],
        "endpoints": {
            "evaluate": "POST /evaluate",
            "health": "GET /health",
            "module_info": "GET /module-info",
        },
    }


@app.post("/evaluate", response_model=MoEEvaluationResponse, tags=["Evaluation"])
async def evaluate(request: EvaluationRequest):
    session_id = request.session_id or str(uuid.uuid4())
    evaluation_id = str(uuid.uuid4())
    timestamp = datetime.now(timezone.utc).isoformat()
    start = time.time()

    selected = select_experts(request.prompt, request.context)

    async with httpx.AsyncClient() as client:
        tasks = [call_expert(client, expert_cfg, request) for expert_cfg in selected]
        results = await asyncio.gather(*tasks)

    if not results:
        raise HTTPException(status_code=503, detail="No experts available.")

    final_verdict, final_conf, final_harm, aggregate_reasoning = aggregate_results(results)
    latency_ms = round((time.time() - start) * 1000, 2)

    response = MoEEvaluationResponse(
        module_id=MOE_CFG["module_id"],
        module_name=MOE_CFG["module_name"],
        session_id=session_id,
        evaluation_id=evaluation_id,
        timestamp=timestamp,
        final_verdict=final_verdict,
        final_confidence_score=final_conf,
        final_harm_level=final_harm,
        routing_mode=ROUTING_CFG.get("mode", "all"),
        selected_experts=[e["name"] for e in selected],
        expert_results=results,
        aggregate_reasoning=aggregate_reasoning,
        latency_ms=latency_ms,
    )

    audit_entry = {
        "event": "moe_evaluation",
        "timestamp": timestamp,
        "session_id": session_id,
        "evaluation_id": evaluation_id,
        "module_id": MOE_CFG["module_id"],
        "selected_experts": [e["name"] for e in selected],
        "final_verdict": final_verdict,
        "final_confidence_score": final_conf,
        "final_harm_level": final_harm,
        "latency_ms": latency_ms,
    }
    write_audit_log(audit_entry)

    logger.info(
        "MoE evaluation %s | verdict=%s | confidence=%.2f | latency=%.0fms",
        evaluation_id,
        final_verdict,
        final_conf,
        latency_ms,
    )

    return response
