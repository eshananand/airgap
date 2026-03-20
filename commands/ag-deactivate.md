---
description: Remove airgap auto-activation from the current project
---
<!-- v1.0 -->
# Deactivate Airgap Auto-Routing

> Remove automatic routing of natural language requests to airgap workflows for this project.

---

## Process

1. **Check current state** — Read `.claude/CLAUDE.md` in the current project directory.
   - If the file doesn't exist: inform the user that airgap is not activated in this project. Stop.

2. **Find markers** — Look for `<!-- AIRGAP:START -->` and `<!-- AIRGAP:END -->` markers.
   - If no markers found: inform the user that airgap is not activated in this project (CLAUDE.md exists but has no airgap routing). Stop.

3. **Remove routing section** — Delete everything from `<!-- AIRGAP:START -->` to `<!-- AIRGAP:END -->` (inclusive). Preserve all other content in the file.

4. **Clean up** — If the file is now empty (or contains only whitespace), delete it. If the `.claude/` directory is now empty, remove it too.

5. **Confirm deactivation** — Tell the user:

> Airgap auto-routing has been removed from this project. Slash commands (`/ag-debug`, `/ag-test`, etc.) are still available — only the automatic routing has been disabled. Run `/ag-activate` to re-enable.
