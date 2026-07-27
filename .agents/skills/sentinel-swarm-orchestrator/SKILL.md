---
name: sentinel-swarm-orchestrator
description: A protocol for leveraging multi-agent swarms in Antigravity to build complex modules efficiently and in parallel. Use this to orchestrate specialized subagents.
---

# Sentinel Swarm Orchestrator

When building a large module or feature that would exceed context limits or take too long sequentially, act as an **Orchestrator Agent** and spawn specialized subagents using the `invoke_subagent` tool.

## 1. Prerequisites
Before spawning a swarm, you MUST have an approved `module_design.md` artifact so all subagents share the same blueprint and data structures.

## 2. Spawning the Swarm
Use the `invoke_subagent` tool to spawn subagents concurrently. Set the `TypeName` to `"self"` so they inherit your file-writing capabilities.

### Example Invocation:
```json
{
  "Subagents": [
    {
      "TypeName": "self",
      "Role": "Data Layer Subagent",
      "Prompt": "You are the Data Layer Agent. Read module_design.md. Implement the models and Riverpod StreamProviders for the 'Incidents' module. Follow the 200-line rule. Reply when finished.",
      "Workspace": "inherit"
    },
    {
      "TypeName": "self",
      "Role": "UI Layer Subagent",
      "Prompt": "You are the UI Layer Agent. Read module_design.md. Build the UI screens and widgets for the 'Incidents' module. Use dummy providers until the Data Layer is done. Follow the 200-line rule. Reply when finished.",
      "Workspace": "inherit"
    }
  ]
}
```

## 3. Orchestration & Review
- You (the parent) do not need to poll. You will receive messages when the subagents finish.
- If a subagent encounters errors (e.g., `flutter analyze` fails), send them a message using the `send_message` tool with the error logs so they can fix it.
- Once all subagents report success, you MUST run a final `flutter analyze` to ensure the integration between the UI and Data layers is seamless.
