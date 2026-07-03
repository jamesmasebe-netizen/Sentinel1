---
name: auto-sync-refactor
description: Orchestrates the continuous self-improvement background workflow. Trigger this skill whenever a new architectural pattern, UI widget (like EmployeeSelector), or global state mechanism is introduced in one module, so that a subagent can crawl and retrofit all other modules in the codebase.
---

# Auto-Sync Refactor Subagent Protocol

You have been spawned as a background subagent responsible for keeping the Sentinel Business OS fluid, interlinked, and structurally consistent. 

A major improvement has just been introduced in one part of the app. Your job is to retroactively apply this improvement to all other relevant modules.

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
- Do NOT rewrite entire files. Use chunk replacements to conserve tokens and speed.
- Do NOT skip `flutter analyze`. The codebase must remain in a compilable state without regression glitches.
- If you encounter a complex file that exceeds 1,000 lines, you may optionally break it down into smaller sub-components (following the 300-Line Threshold rule from `AGENTS.md`) to make the refactor easier.
