from pydantic import BaseModel, Field
from typing import Any, Dict, Optional


class EvaluateRequest(BaseModel):
    use_case_title: str = Field(..., description="Short title of the proposed AI use case")
    description: str = Field(..., description="Description of the AI system, purpose, data, users, and deployment context")
    intended_users: Optional[str] = None
    affected_groups: Optional[str] = None
    data_sources: Optional[str] = None
    deployment_context: Optional[str] = None
    current_controls: Optional[str] = None
    extra_context: Optional[Dict[str, Any]] = None


class AgentResponse(BaseModel):
    agent_id: str
    agent_name: str
    raw_text: str
    parsed: Optional[Dict[str, Any]] = None
