---
name: auto-sync-refactor
description: Orchestrates the continuous self-improvement background workflow. Trigger this skill whenever a new architectural pattern, UI widget (like EmployeeSelector), or global state mechanism is introduced in one module, so that a subagent can crawl and retrofit all other modules in the codebase.
---

# Auto-Sync Refactor Subagent Protocol

You have been spawned as a background subagent responsible for keeping the Sentinel Business OS fluid, interlinked, and structurally consistent. 

A major improvement has just been introduced in one part of the app. Your job is to retroactively apply this improvement to all other relevant modules.

## Spawning this Subagent (For Parent Agents)

When you (the parent agent) complete a major architectural improvement, you MUST invoke this skill using the `invoke_subagent` tool. Use the `self` TypeName so the subagent has file-editing capabilities.

```json
{
  "Subagents": [
    {
      "TypeName": "self", 
      "Role": "Refactor Subagent",
      "Prompt": "Execute the auto-sync-refactor protocol to replace [Old Pattern] with [New Pattern]...",
      "Workspace": "inherit"
    }
  ]
}
```

## Workflow

1. **Understand the Target Pattern:** 
   The parent agent's prompt will specify the "Old Pattern" and the "New Pattern" (e.g., replacing manual `TextFormField` with `EmployeeSelector`, or replacing inline `StreamBuilder` with `ref.watch(provider)`).
   
2. **Scan the Codebase:**
   Use `grep_search` to find all occurrences of the "Old Pattern" across the `lib/features/` directory.

3. **Systemic Replacement:**
   - Go through each affected file one by one.
   - Use `multi_replace_file_content` to surgically replace the old pattern with the new pattern.
   - Ensure you add any missing imports for the new components (e.g., importing `ds_widgets.dart` or the relevant provider).

4. **Verify Integrity:**
   After all files have been modified, you MUST run the terminal command `flutter analyze`. 
   If `flutter analyze` reports any new errors or warnings caused by your refactoring, you must fix them before continuing.

5. **Report Back:**
   When the refactoring and analysis are complete and successful, send a message back to the parent agent summarizing:
   - The number of files touched.
   - The specific modules that are now synchronized.
   - Confirmation that `flutter analyze` passes.

## Strict Rules
- Do NOT rewrite entire files. ALWAYS use the `multi_replace_file_content` tool to perform surgical, chunk-based replacements to conserve tokens and speed.
- Do NOT skip `flutter analyze`. The codebase must remain in a compilable state without regression glitches.
- If you encounter a complex file that exceeds 200 lines, you MUST break it down into smaller sub-components (following the 200-Line Threshold rule from `AGENTS.md`) to make the refactor easier and maintain system health.
