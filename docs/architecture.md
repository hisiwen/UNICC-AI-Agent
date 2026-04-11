# AI_AGENT Architecture Notes

## Why these three agents?

### 1. Standards Compliance Agent
This agent handles external governance frameworks and compliance-style reasoning. It answers: which standards are triggered, where the proposal aligns, where it conflicts, and what obligations or safeguards are missing.

### 2. Safety Dimensions Agent
This agent handles operational and ethical safety evaluation across six dimensions. It answers: how risky is the proposal in practice, which harms are plausible, and which dimensions are most fragile.

### 3. Assurance & Accountability Agent
This agent focuses on implementation confidence. It answers: what evidence is missing, who is responsible, what monitoring and escalation are required, and whether the proposal has enough assurance to move forward.

## Why not one giant agent?
A single agent tends to blur standards, safety, and assurance reasoning. Splitting them improves:
- clearer role separation
- easier debugging
- better explainability for a capstone demo
- simpler expansion later

## Expansion options
If you later want more agents, split further into:
- EU AI Act specialist
- IEEE / ISO specialist
- Bias & fairness specialist
- Privacy specialist
- Deception & transparency specialist
- Accountability & assurance specialist
