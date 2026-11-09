---
name: model-routing
description: "Small admin tasks go to a cheaper-model subagent, never a /model switch of the orchestrator"
metadata:
  node_type: memory
  type: feedback
  originSessionId: a87fa624-19d3-40f5-a96c-142694547309
  modified: 2026-11-07T17:01:40.848Z
---

Admin tasks that are small (status, commits, routine checks) belong to a subagent on a cheaper model, not to `/model sonnet` in the orchestrator session.

**Why:** the designer (2026-11-07) rejected switching the orchestrator's model by hand; delegation keeps the main context clean and the routing automatic.

**How to apply:** when a task is small and self-contained, dispatch it to a Sonnet/Haiku subagent (e.g. Rex for scripts) rather than suggesting a model switch. Related: [[cost-rules]].
