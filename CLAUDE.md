@.agents/AGENTS.md

## Claude Code specifics

- **Skills:** `.agents/skills/` has 7 project skills written for Antigravity/Gemini (`auto-sync-refactor`, `gemini-ai-integration`, `sentinel-module-generator`, `saas-production-readiness`, `sentinel-defensive-crud`, `sentinel-deep-link-enforcer`, `sentinel-swarm-orchestrator`). They aren't auto-discovered as Claude Code skills — read the relevant `SKILL.md` directly when a task matches one of these areas.
- **Exploration:** `lib/` has 400+ Dart files. Use Explore/Grep and each feature's `README.md` manifest (see AGENTS.md §4) rather than reading the tree wholesale.
