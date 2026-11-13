# Hermes: system metrics (CPU / RAM / GPU / DISK / NET) in the status bar

Adds a second row to the CLI status bar with live Task-Manager-style gauges:

```
CPU 8% · RAM 32% · GPU 0% · DISK 5% · E:0 R:120 Kbps
```

- `CPU` / `RAM` / `GPU` / `DISK` — integer percent, colored by threshold (green → yellow → red).
- `E:` (enviado / upload) and `R:` (recebido / download) — network throughput in Kbps, rolling to Mbps above ~1 Mbps. Matches Task Manager's "Enviar / Receber" columns.
- The row lives under the existing status bar (classic) or footer (modern layout), so it sits right below the cost/quota line from `deepseek-cost-monitor`.

## Behavior

- One PowerShell (WMI) subprocess collects every metric in a single shot (~2-3 s) in a
  background thread — the render loop never blocks, and a failed poll is cached (empty)
  and retried after the TTL, so a transient error doesn't spam subprocesses.
- Values refresh every ~5 s. The first poll also wakes the render loop, so the row keeps
  updating even while the prompt is idle (the idle spinner loop never repaints on a timer).
- The row stays hidden until the first poll returns data (~3 s after start).
- Non-Windows platforms render nothing (the collector returns `{}`).

## Install

1. Apply the **cost/balance patch first** (this patch's insertion point sits between the
   cost methods, so it must be applied on top of them), then this one:

```bash
cd "$HERMES_HOME/hermes-agent"     # or ~/.hermes/hermes-agent on Linux/macOS
git apply "$AI_TOOLS/deepseek-cost-monitor/cli_status_bar_cost_balance.patch"
git apply "$AI_TOOLS/sysmetrics/sysmetrics.patch"
```

2. Restart hermes (quit and relaunch — `/new` does **not** reload already-imported modules).

3. The metrics row is **on by default**. To turn it off:

```bash
hermes config set display.sysmetrics false
```

## Requirements

- Windows (the collector shells out to `powershell.exe` + WMI/CIM).
- GPU read via `Win32_PerfFormattedData_GPUPerformanceCounters_GPUEngine` — present on
  Windows 10 1709+. On machines without that class the GPU gauge shows `--`.
- Disk read is `100 − %IdleTime` on the `C:` logical disk (the accurate "active time"
  that Task Manager shows, avoiding `PercentDiskTime`'s known >100% overshoot).

## Caveats

- `hermes update` / `git pull` overwrites the patched files — reapply **both** patches
  (cost first, then sysmetrics) afterwards.
- Metrics are per-machine, not per-session; they are the same numbers you'd see in
  Task Manager's Performance tab (plus network throughput instead of the Wi-Fi signal %,
  which `netsh` only exposes when Windows Location services are on).
- The 2nd row appears only after the first successful poll; before that the bar is one row.

## Files

- `sysmetrics.patch` — the code patch (`git apply`, after the cost patch). Regenerated
  2026-11-13 against HEAD `3b421578`.
