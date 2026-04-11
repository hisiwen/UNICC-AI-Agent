import React, { useMemo, useState } from "react";
import axios from "axios";
import {
  Shield,
  Scale,
  ClipboardCheck,
  AlertTriangle,
  CheckCircle2,
  FileWarning,
  Loader2,
} from "lucide-react";
import {
  BarChart,
  Bar,
  CartesianGrid,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
} from "recharts";

const API_URL = "http://localhost:8080/run";

const defaultForm = {
  use_case_title: "AI Hiring Screening System",
  description:
    "An AI system ranks job applicants using resume text, application history, and screening question responses before human recruiter review.",
  intended_users: "HR recruiters and talent acquisition managers",
  affected_groups:
    "Job applicants, including potentially protected groups and international applicants",
  data_sources: "Resume text, application history, screening questions",
  deployment_context:
    "Used internally by a hiring team to prioritize candidates before final human review",
  current_controls: "Human recruiter review of top-ranked candidates",
  extra_context: {
    geography: "US and international applicants",
    sensitive_domain: true,
    human_oversight: true,
  },
};

const inputStyle = {
  width: "100%",
  padding: "12px 14px",
  borderRadius: 14,
  border: "1px solid #d1d5db",
  fontSize: 14,
  boxSizing: "border-box",
};

const textareaStyle = {
  ...inputStyle,
  resize: "vertical",
  fontFamily: "inherit",
};

const toggleButtonStyle = {
  border: "1px solid #d1d5db",
  borderRadius: 14,
  padding: "10px 14px",
  cursor: "pointer",
  fontWeight: 600,
};

function cardStyle() {
  return {
    background: "#ffffff",
    border: "1px solid #e5e7eb",
    borderRadius: 20,
    padding: 20,
    boxShadow: "0 4px 16px rgba(0,0,0,0.04)",
  };
}

function badgeStyle(bg, color) {
  return {
    display: "inline-block",
    padding: "6px 12px",
    borderRadius: 999,
    background: bg,
    color,
    fontSize: 12,
    fontWeight: 600,
  };
}

function getDecisionTone(decision) {
  const value = (decision || "").toLowerCase();
  if (value.includes("reject")) {
    return {
      bg: "#fee2e2",
      color: "#b91c1c",
      panel: "#fff1f2",
      icon: AlertTriangle,
    };
  }
  if (value.includes("flag")) {
    return {
      bg: "#fef3c7",
      color: "#92400e",
      panel: "#fffbeb",
      icon: FileWarning,
    };
  }
  if (value.includes("condition")) {
    return {
      bg: "#dbeafe",
      color: "#1d4ed8",
      panel: "#eff6ff",
      icon: Shield,
    };
  }
  return {
    bg: "#dcfce7",
    color: "#15803d",
    panel: "#f0fdf4",
    icon: CheckCircle2,
  };
}

function SummaryBlock({ title, items, emptyText }) {
  return (
    <div style={cardStyle()}>
      <h3 style={{ marginTop: 0, marginBottom: 12 }}>{title}</h3>
      {items?.length ? (
        <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
          {items.map((item, index) => (
            <span key={index} style={badgeStyle("#f3f4f6", "#111827")}>
              {item}
            </span>
          ))}
        </div>
      ) : (
        <p style={{ color: "#6b7280", margin: 0 }}>{emptyText}</p>
      )}
    </div>
  );
}

function AgentCard({ agent }) {
  const parsed = agent?.parsed || {};

  return (
    <div style={cardStyle()}>
      <h3 style={{ marginTop: 0 }}>{agent.agent_name}</h3>

      {parsed.executive_summary && (
        <div style={{ marginBottom: 16 }}>
          <div style={{ fontWeight: 700, marginBottom: 6 }}>Executive summary</div>
          <div style={{ color: "#4b5563" }}>{parsed.executive_summary}</div>
        </div>
      )}

      {Array.isArray(parsed.triggered_standards) && parsed.triggered_standards.length > 0 && (
        <div style={{ marginBottom: 16 }}>
          <div style={{ fontWeight: 700, marginBottom: 6 }}>Triggered standards</div>
          <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
            {parsed.triggered_standards.map((item, index) => (
              <span key={index} style={badgeStyle("#eef2ff", "#3730a3")}>
                {item}
              </span>
            ))}
          </div>
        </div>
      )}

      {Array.isArray(parsed.key_gaps) && parsed.key_gaps.length > 0 && (
        <div style={{ marginBottom: 16 }}>
          <div style={{ fontWeight: 700, marginBottom: 6 }}>Key gaps</div>
          <ul style={{ margin: 0, paddingLeft: 18, color: "#4b5563" }}>
            {parsed.key_gaps.map((item, index) => (
              <li key={index}>{item}</li>
            ))}
          </ul>
        </div>
      )}

      {Array.isArray(parsed.required_controls) && parsed.required_controls.length > 0 && (
        <div style={{ marginBottom: 16 }}>
          <div style={{ fontWeight: 700, marginBottom: 6 }}>Required controls</div>
          <ul style={{ margin: 0, paddingLeft: 18, color: "#4b5563" }}>
            {parsed.required_controls.map((item, index) => (
              <li key={index}>{item}</li>
            ))}
          </ul>
        </div>
      )}

      {Array.isArray(parsed.evidence_gaps) && parsed.evidence_gaps.length > 0 && (
        <div style={{ marginBottom: 16 }}>
          <div style={{ fontWeight: 700, marginBottom: 6 }}>Evidence gaps</div>
          <ul style={{ margin: 0, paddingLeft: 18, color: "#4b5563" }}>
            {parsed.evidence_gaps.map((item, index) => (
              <li key={index}>{item}</li>
            ))}
          </ul>
        </div>
      )}

      {Array.isArray(parsed.assurance_controls) && parsed.assurance_controls.length > 0 && (
        <div style={{ marginBottom: 16 }}>
          <div style={{ fontWeight: 700, marginBottom: 6 }}>Assurance controls</div>
          <ul style={{ margin: 0, paddingLeft: 18, color: "#4b5563" }}>
            {parsed.assurance_controls.map((item, index) => (
              <li key={index}>{item}</li>
            ))}
          </ul>
        </div>
      )}

      {parsed.recommendation && (
        <div>
          <div style={{ fontWeight: 700, marginBottom: 6 }}>Recommendation</div>
          <span style={badgeStyle("#f3f4f6", "#111827")}>{parsed.recommendation}</span>
        </div>
      )}
    </div>
  );
}

export default function App() {
  const [form, setForm] = useState(defaultForm);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [result, setResult] = useState(null);

  const decisionTone = getDecisionTone(result?.final_decision);
  const DecisionIcon = decisionTone.icon;

  const safetyAgent = useMemo(() => {
    return result?.agent_results?.find(
      (agent) => agent.agent_id === "safety_dimensions_agent"
    );
  }, [result]);

  const safetyChartData = useMemo(() => {
    const scores = safetyAgent?.parsed?.dimension_scores || [];
    return scores.map((item) => ({
      name: item.dimension,
      score: item.score,
    }));
  }, [safetyAgent]);

  const updateField = (key, value) => {
    setForm((prev) => ({ ...prev, [key]: value }));
  };

  const updateExtraContext = (key, value) => {
    setForm((prev) => ({
      ...prev,
      extra_context: {
        ...prev.extra_context,
        [key]: value,
      },
    }));
  };

  const runEvaluation = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError("");

    try {
      const response = await axios.post(API_URL, form, {
        headers: { "Content-Type": "application/json" },
      });
      setResult(response.data);
    } catch (err) {
      const detail = err?.response?.data?.detail || err?.message || "Request failed.";
      setError(detail);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ minHeight: "100vh", background: "#f8fafc", color: "#0f172a" }}>
      <div style={{ maxWidth: 1280, margin: "0 auto", padding: 24 }}>
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "1.4fr 0.8fr",
            gap: 20,
            marginBottom: 24,
          }}
        >
          <div
            style={{
              borderRadius: 24,
              padding: 28,
              color: "white",
              background:
                "linear-gradient(135deg, #0f172a 0%, #1e293b 50%, #334155 100%)",
            }}
          >
            <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
              <div style={{ background: "rgba(255,255,255,0.12)", padding: 12, borderRadius: 16 }}>
                <Shield size={24} />
              </div>
              <div>
                <h1 style={{ margin: 0, fontSize: 34 }}>AI_AGENT Governance Dashboard</h1>
                <p style={{ margin: "8px 0 0 0", color: "#cbd5e1" }}>
                  Multi-agent evaluation across standards, safety dimensions, and assurance controls.
                </p>
              </div>
            </div>

            <div
              style={{
                display: "grid",
                gridTemplateColumns: "repeat(3, 1fr)",
                gap: 14,
                marginTop: 24,
              }}
            >
              <div style={{ background: "rgba(255,255,255,0.10)", borderRadius: 18, padding: 16 }}>
                <div style={{ display: "flex", alignItems: "center", gap: 8, color: "#cbd5e1" }}>
                  <Scale size={16} /> Standards
                </div>
                <div style={{ marginTop: 10, fontWeight: 700 }}>
                  EU AI Act, ISO, IEEE, UNESCO
                </div>
              </div>
              <div style={{ background: "rgba(255,255,255,0.10)", borderRadius: 18, padding: 16 }}>
                <div style={{ display: "flex", alignItems: "center", gap: 8, color: "#cbd5e1" }}>
                  <AlertTriangle size={16} /> Safety
                </div>
                <div style={{ marginTop: 10, fontWeight: 700 }}>
                  Bias, privacy, transparency, accountability
                </div>
              </div>
              <div style={{ background: "rgba(255,255,255,0.10)", borderRadius: 18, padding: 16 }}>
                <div style={{ display: "flex", alignItems: "center", gap: 8, color: "#cbd5e1" }}>
                  <ClipboardCheck size={16} /> Assurance
                </div>
                <div style={{ marginTop: 10, fontWeight: 700 }}>
                  Audit trails, controls, fallback readiness
                </div>
              </div>
            </div>
          </div>

          <div
            style={{
              ...cardStyle(),
              background: decisionTone.panel,
              border: "1px solid #e5e7eb",
            }}
          >
            <div style={{ display: "flex", justifyContent: "space-between", gap: 12 }}>
              <div>
                <div style={{ fontSize: 14, color: "#6b7280", fontWeight: 600 }}>
                  Current system decision
                </div>
                <div style={{ display: "flex", alignItems: "center", gap: 14, marginTop: 14 }}>
                  <div
                    style={{
                      background: "#ffffff",
                      padding: 12,
                      borderRadius: 16,
                      boxShadow: "0 2px 10px rgba(0,0,0,0.05)",
                    }}
                  >
                    <DecisionIcon size={24} />
                  </div>
                  <div>
                    <h2 style={{ margin: 0, fontSize: 28 }}>
                      {result?.final_decision || "Awaiting evaluation"}
                    </h2>
                    <p style={{ margin: "8px 0 0 0", color: "#6b7280" }}>
                      Submit a use case to get the combined governance judgment.
                    </p>
                  </div>
                </div>
              </div>
              {result?.final_decision && (
                <span style={badgeStyle(decisionTone.bg, decisionTone.color)}>Final output</span>
              )}
            </div>
          </div>
        </div>

        <div
          style={{
            display: "grid",
            gridTemplateColumns: "0.95fr 1.05fr",
            gap: 24,
          }}
        >
          <div style={cardStyle()}>
            <h2 style={{ marginTop: 0 }}>Evaluate an AI use case</h2>
            <form onSubmit={runEvaluation} style={{ display: "grid", gap: 14 }}>
              <div>
                <label style={{ display: "block", marginBottom: 6, fontWeight: 600 }}>
                  Use case title
                </label>
                <input
                  value={form.use_case_title}
                  onChange={(e) => updateField("use_case_title", e.target.value)}
                  style={inputStyle}
                />
              </div>

              <div>
                <label style={{ display: "block", marginBottom: 6, fontWeight: 600 }}>
                  Description
                </label>
                <textarea
                  rows={4}
                  value={form.description}
                  onChange={(e) => updateField("description", e.target.value)}
                  style={textareaStyle}
                />
              </div>

              <div>
                <label style={{ display: "block", marginBottom: 6, fontWeight: 600 }}>
                  Intended users
                </label>
                <input
                  value={form.intended_users}
                  onChange={(e) => updateField("intended_users", e.target.value)}
                  style={inputStyle}
                />
              </div>

              <div>
                <label style={{ display: "block", marginBottom: 6, fontWeight: 600 }}>
                  Affected groups
                </label>
                <input
                  value={form.affected_groups}
                  onChange={(e) => updateField("affected_groups", e.target.value)}
                  style={inputStyle}
                />
              </div>

              <div>
                <label style={{ display: "block", marginBottom: 6, fontWeight: 600 }}>
                  Data sources
                </label>
                <input
                  value={form.data_sources}
                  onChange={(e) => updateField("data_sources", e.target.value)}
                  style={inputStyle}
                />
              </div>

              <div>
                <label style={{ display: "block", marginBottom: 6, fontWeight: 600 }}>
                  Deployment context
                </label>
                <textarea
                  rows={3}
                  value={form.deployment_context}
                  onChange={(e) => updateField("deployment_context", e.target.value)}
                  style={textareaStyle}
                />
              </div>

              <div>
                <label style={{ display: "block", marginBottom: 6, fontWeight: 600 }}>
                  Current controls
                </label>
                <textarea
                  rows={3}
                  value={form.current_controls}
                  onChange={(e) => updateField("current_controls", e.target.value)}
                  style={textareaStyle}
                />
              </div>

              <div>
                <label style={{ display: "block", marginBottom: 6, fontWeight: 600 }}>
                  Geography
                </label>
                <input
                  value={form.extra_context.geography}
                  onChange={(e) => updateExtraContext("geography", e.target.value)}
                  style={inputStyle}
                />
              </div>

              <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>
                <button
                  type="button"
                  onClick={() =>
                    updateExtraContext("sensitive_domain", !form.extra_context.sensitive_domain)
                  }
                  style={{
                    ...toggleButtonStyle,
                    background: form.extra_context.sensitive_domain ? "#0f172a" : "#fff",
                    color: form.extra_context.sensitive_domain ? "#fff" : "#111827",
                  }}
                >
                  Sensitive domain: {form.extra_context.sensitive_domain ? "Yes" : "No"}
                </button>

                <button
                  type="button"
                  onClick={() =>
                    updateExtraContext("human_oversight", !form.extra_context.human_oversight)
                  }
                  style={{
                    ...toggleButtonStyle,
                    background: form.extra_context.human_oversight ? "#0f172a" : "#fff",
                    color: form.extra_context.human_oversight ? "#fff" : "#111827",
                  }}
                >
                  Human oversight: {form.extra_context.human_oversight ? "Yes" : "No"}
                </button>
              </div>

              {error && (
                <div
                  style={{
                    border: "1px solid #fecaca",
                    background: "#fef2f2",
                    color: "#b91c1c",
                    padding: 12,
                    borderRadius: 14,
                  }}
                >
                  {error}
                </div>
              )}

              <button
                type="submit"
                disabled={loading}
                style={{
                  border: 0,
                  borderRadius: 16,
                  padding: "12px 18px",
                  background: "#0f172a",
                  color: "white",
                  fontWeight: 700,
                  cursor: "pointer",
                }}
              >
                <span style={{ display: "inline-flex", alignItems: "center", gap: 8 }}>
                  {loading ? <Loader2 size={16} /> : null}
                  {loading ? "Running evaluation..." : "Run evaluation"}
                </span>
              </button>
            </form>
          </div>

          <div style={{ display: "grid", gap: 20 }}>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 16 }}>
              <SummaryBlock
                title="Cross-agent risks"
                items={result?.summary?.cross_agent_risks || []}
                emptyText="No major cross-agent risks yet."
              />
              <SummaryBlock
                title="Cross-agent gaps"
                items={result?.summary?.cross_agent_gaps || []}
                emptyText="No major cross-agent gaps yet."
              />
              <SummaryBlock
                title="Cross-agent controls"
                items={result?.summary?.cross_agent_controls || []}
                emptyText="No controls generated yet."
              />
            </div>

            <div style={cardStyle()}>
              <h2 style={{ marginTop: 0 }}>Safety dimension scores</h2>
              {safetyChartData.length ? (
                <div style={{ width: "100%", height: 320 }}>
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={safetyChartData} margin={{ top: 10, right: 10, left: -20, bottom: 40 }}>
                      <CartesianGrid vertical={false} strokeDasharray="3 3" />
                      <XAxis dataKey="name" angle={-25} textAnchor="end" interval={0} height={70} />
                      <YAxis domain={[0, 5]} />
                      <Tooltip />
                      <Bar dataKey="score" radius={[8, 8, 0, 0]} />
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              ) : (
                <p style={{ color: "#6b7280" }}>Run an evaluation to populate the chart.</p>
              )}
            </div>
          </div>
        </div>

        <div
          style={{
            display: "grid",
            gridTemplateColumns: "repeat(3, 1fr)",
            gap: 20,
            marginTop: 24,
          }}
        >
          {(result?.agent_results || []).map((agent) => (
            <AgentCard key={agent.agent_id} agent={agent} />
          ))}
        </div>
      </div>
    </div>
  );
}