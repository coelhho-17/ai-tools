# Hermes + DeepSeek: session cost & account balance in the status bar

Two segments added to the classic CLI status bar, gated behind the existing
`display.show_cost` flag:

- `~$X.XX` — estimated cost of the **current session** (accumulates per turn)
- `💰 $X.XX` — DeepSeek **account balance** remaining (live, from `GET /user/balance`, cached 5 min)

```
☤ deepseek-v4-pro │ ~$0.47 │ 💰 $3.46 │ ███ 12% │ ↑ 23 t/s │ ...
```

## What it does NOT do

DeepSeek has **no public API** for account cost, request count, or token count.
Those totals exist only on the Usage page (platform.deepseek.com) behind login.
This feature shows the two things that *are* programmatically available:

- session cost — Hermes already estimates this per turn
  (`agent.session_estimated_cost_usd`, accumulated in `agent/turn_usage.py`)
- account balance — the only account number DeepSeek exposes via API

## Install

1. Apply the patch to your hermes-agent source tree:

```bash
cd "$HERMES_HOME/hermes-agent"     # or ~/.hermes/hermes-agent on Linux/macOS
git apply cli_status_bar_cost_balance.patch
```

2. Enable the flag (it was a documented but previously unimplemented config key):

```bash
hermes config set display.show_cost true
```

3. Restart hermes (quit and relaunch — `/new` does **not** reload already-imported
   Python modules).

## What you'll see

- `~$X.XX` appears once the session has incurred cost (> $0); hidden at session start.
- `💰 $X.XX` appears as soon as the first balance fetch completes — even with $0 session cost.
- Balance refreshes every ~5 minutes in a background thread; it never blocks rendering,
  and a failed fetch is cached (empty) and retried after the TTL, so a dead network
  doesn't hammer the endpoint.
- Only active for DeepSeek's native endpoint (`provider == "deepseek"` or
  `api.deepseek.com` in `base_url`). Other providers render nothing.
- Segments are placed immediately after the model so the far-right session-title badge
  never trims them off on narrow terminals.

## Optional: standalone balance script

`deepseek-balance` prints the balance (and a derived account cost) from the terminal.
Drop it on your `PATH` and run:

```bash
deepseek-balance
# DeepSeek USD | balance: $3.46 | granted: $0.00 | topped-up: $3.46
# estimated cost (top-up $10.00): $6.54
```

Because the API only returns balance, account cost is *derived* as
`total topped up − current balance`. Set your total top-up via the env var
`DEEPSEEK_TOPUP_TOTAL` (default `10.00`):

```bash
DEEPSEEK_TOPUP_TOTAL=25.00 deepseek-balance
```

The script reads `DEEPSEEK_API_KEY` from the Hermes `.env` (`$HERMES_HOME/.env`,
falling back to `~/.hermes/.env`) and never prints the key.

## Caveats

- `~$X.XX` is a per-session *estimate*, not the account total.
- `hermes update` / `git pull` overwrites the patched file — reapply the patch afterwards.
- Balance can lag the platform panel by up to ~5 min (the panel's own stated delay).

## Mapping to the DeepSeek Usage page

| Usage page field      | Where it comes from here                          |
|-----------------------|---------------------------------------------------|
| Topped-up balance     | `💰` segment (`total_balance`, live API)          |
| Total cost            | derived: top-up total − balance (script only)     |
| API requests / Tokens | not available via API — panel only                |

## Files

- `cli_status_bar_cost_balance.patch` — the code patch (`git apply`).
- `deepseek-balance` — standalone balance script (optional).

## Contributing upstream

If you'd rather have this shipped to every Hermes + DeepSeek user automatically,
the right move is a pull request against
[github.com/NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent).
The patch already follows the repo's status-bar conventions (segments placed after
the model segment; config flag read with caching; import helpers from
`agent.usage_pricing`). See the repo's contributor guide for the commit/PR format.
