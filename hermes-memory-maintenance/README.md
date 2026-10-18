# Hermes Memory Maintenance

Check how full your Hermes memory is, back it up, and clean it up (consolidate) to free space.

## What this is

Hermes keeps two kinds of persistent memory, stored as plain-text files and injected into EVERY turn of every session:

- `MEMORY.md` — the agent's own notes (environment facts, conventions, lessons).
- `USER.md` — the user profile (who you are, preferences, style).

Because these are always in context, they compete with the conversation budget — so Hermes caps them small on purpose (`memory_char_limit` 2200 ≈ 800 tokens, `user_char_limit` 1375 ≈ 500 tokens). Keeping them lean means fewer wasted tokens and more room for real work.

## Check usage %

The % is shown at the top of every session:
`MEMORY [NN% — X/2200 chars]` and `USER PROFILE [NN% — X/1375 chars]`.

To check on demand:

- `hermes config get memory.memory_char_limit` (and `memory.user_char_limit`) for the limits.
- The files live at `$HERMES_HOME/memories/` (`C:\Users\<you>\AppData\Local\hermes\memories\` on Windows, `~/.hermes/memories/` on Linux/macOS). Usage % = file size ÷ its limit.
- The agent's `memory` tool reports usage after every write (e.g. `30% — 671/2,200 chars`).

Note: `hermes memory` (the CLI subcommand) manages external memory-provider plugins (retaindb, byterover, …), NOT these built-in files — it has no "view %" or "backup" for MEMORY.md/USER.md.

## Back up

```bash
TS=$(date +%Y%m%d_%H%M%S)
MEMDIR="${HERMES_HOME:-$HOME/AppData/Local/hermes}/memories"   # Linux/macOS: $HOME/.hermes/memories
mkdir -p "$HOME/Documents/hermes-memory-backup/$TS"
cp "$MEMDIR/MEMORY.md" "$HOME/Documents/hermes-memory-backup/$TS/"
cp "$MEMDIR/USER.md"   "$HOME/Documents/hermes-memory-backup/$TS/"
```

Restore = copy the two files back over the originals.

## Consolidate (free up space)

Memory is the narrow store for facts that apply to EVERY session regardless of task. Procedures, pitfalls and task-specific corrections belong in SKILLS (loaded on demand), not memory.

For each memory entry, decide:

| Entry is… | Action |
|---|---|
| A procedure / pitfall / correction for a task type | MOVE it to that task's skill, then remove from memory |
| A completed-work log, task progress, or temporary TODO | DROP it (belongs in your notes / session history) |
| A stable environment fact with no skill home | KEEP, compressed to the essential pointer (details live in notes/skills) |

Workflow:

1. Back up (above).
2. Before deleting a procedure entry, patch the target skill with anything that exists ONLY in memory, so nothing is lost.
3. In one `memory` tool batch: `remove` each stale entry (by a unique ASCII substring), then `add` the compressed replacements.
4. Verify — the tool reports the new % and entry count.

## Why not just raise the limit?

You can (`hermes config set memory.memory_char_limit NNNN`), but the limit is small on purpose: memory is always-on context, so a bigger limit means more tokens burned every single turn. Consolidation (lean memory + on-demand skills) is cheaper than a bigger memory.
