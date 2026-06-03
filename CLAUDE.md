# Claude Standing Instructions

## Skill Auto-Invocation — Required on Every Task

Before responding to any user request, you MUST:

1. **Scan all available skills** listed in the skill registry.
2. **Identify every skill whose description matches** any part of the task — not just the most obvious one. A task about a React component might trigger `web-implementation`, `ui-ux-design`, `accessibility`, `color-specialist`, and `coding-notes` simultaneously.
3. **Invoke all matching skills** using the Skill tool before generating your response. Do not wait for the user to ask. Do not invoke only one skill when multiple apply.
4. **Layer skills for complex tasks.** Multi-domain tasks require multi-skill execution. A cannabis delivery feature might need `cannabis-delivery-compliance` + `backend-design` + `web-deployment` + `cybersecurity` all at once.

### Decision Rule

Ask yourself: *"Would a specialist in this skill produce a meaningfully better output for this task?"* If yes, invoke it — even if the skill is not the primary focus of the request.

### Skill Invocation Threshold

- **Always invoke** skills that directly match the task domain.
- **Invoke supporting skills** when they improve quality (e.g., `accessibility` on any UI task, `cybersecurity` on any auth or API task, `coding-notes` on any code delivery).
- **Invoke `token-saver`** when the user explicitly wants dense, no-filler output.
- **Invoke `debugger`** any time a bug, error, or stack trace is present.
- **Invoke `financial-analyst`** any time math, pricing, or financial modeling is involved.

### Never Skip Skills to Save Time

Speed is not a reason to skip a skill. The user has explicitly set up this skill library to produce the best possible outcomes. Always use it fully.
