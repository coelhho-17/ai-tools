# ai-tools

A collection of small, useful tools and patches for AI workflows.

## Tools

- [deepseek-cost-monitor](deepseek-cost-monitor/) — adds per-session cost
  (`~$X.XX`) and live DeepSeek account balance (`💰 $X.XX`) to the Hermes
  Agent CLI status bar, gated behind the existing `display.show_cost` flag.
- [sysmetrics](sysmetrics/) — adds a second status-bar row with live
  Task-Manager-style gauges (CPU / RAM / GPU / DISK / NET throughput).
- [hermes-memory-maintenance](hermes-memory-maintenance/) — check Hermes
  memory usage %, back it up, and consolidate it to free space. A guide plus
  the backup/cleanup procedure.

## Install the Hermes status-bar patches

The cost/balance and sysmetrics patches apply to the `hermes-agent` source
checkout (git install). One command installs both:

```bash
bash install.sh                         # default: $HOME/AppData/Local/hermes
HERMES_HOME=~/.hermes bash install.sh   # override the Hermes home (Linux/macOS)
```

Then restart Hermes (`/quit` + `hermes`) — `/new` does not reload already-imported
Python modules.

The patches are verified to apply cleanly against upstream HEAD `3b421578`
through `882cbc99e4` (2026-11-13); if a future `hermes update` moves the
checkout past that and `git apply` fails, regenerate per the READMEs.
