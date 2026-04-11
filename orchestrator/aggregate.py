from typing import Any, Dict, List


DECISION_ORDER = {
    "Reject": 3,
    "Flag for Review": 2,
    "Approve with Conditions": 1,
    "Approve": 0,
}


def derive_final_decision(results: List[Dict[str, Any]]) -> str:
    highest = 0
    final = "Approve"

    for result in results:
        parsed = result.get("parsed") or {}
        decision = parsed.get("recommendation")
        if decision in DECISION_ORDER and DECISION_ORDER[decision] > highest:
            highest = DECISION_ORDER[decision]
            final = decision

    if highest == 0 and results:
        return "Approve with Conditions"
    return final


def summarize_findings(results: List[Dict[str, Any]]) -> Dict[str, Any]:
    summary = {
        "cross_agent_gaps": [],
        "cross_agent_controls": [],
    }

    for result in results:
        parsed = result.get("parsed") or {}
        for key in ["key_gaps", "high_priority_risks", "evidence_gaps"]:
            values = parsed.get(key, [])
            if isinstance(values, list):
                summary["cross_agent_gaps"].extend(values)
        for key in ["required_controls", "mitigations", "assurance_controls"]:
            values = parsed.get(key, [])
            if isinstance(values, list):
                summary["cross_agent_controls"].extend(values)

    # deduplicate while preserving order
    def dedupe(items: List[str]) -> List[str]:
        seen = set()
        output = []
        for item in items:
            if isinstance(item, str) and item not in seen:
                seen.add(item)
                output.append(item)
        return output

    summary["cross_agent_gaps"] = dedupe(summary["cross_agent_gaps"])
    summary["cross_agent_controls"] = dedupe(summary["cross_agent_controls"])
    return summary
