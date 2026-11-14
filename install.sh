#!/usr/bin/env bash
set -euo pipefail

# Instala os patches de status bar (custo/saldo + sysmetrics) no hermes-agent.
#
# Uso:
#   bash install.sh                         # default: $HOME/AppData/Local/hermes
#   HERMES_HOME=~/.hermes bash install.sh   # override (Linux/macOS)
#   HERMES_HOME=/c/Users/x/AppData/Local/hermes bash install.sh
#
# Ordem importa: custo/saldo primeiro, sysmetrics depois (o ponto de inserção
# do sysmetrics fica entre os métodos de custo no cli_status_bar_mixin.py).

AI_TOOLS="$(cd "$(dirname "$0")" && pwd)"
HERMES_HOME="${HERMES_HOME:-$HOME/AppData/Local/hermes}"
DST="$HERMES_HOME/hermes-agent"

# git (nativo Windows) não entende paths MSYS (/c/...); converte se necessário.
native() { cygpath -w "$1" 2>/dev/null || printf '%s' "$1"; }

COST="$(native "$AI_TOOLS/deepseek-cost-monitor/cli_status_bar_cost_balance.patch")"
SYS="$(native "$AI_TOOLS/sysmetrics/sysmetrics.patch")"

if [ ! -d "$DST" ]; then
  echo "ERRO: hermes-agent não encontrado em $DST" >&2
  echo "Defina HERMES_HOME para o diretório do Hermes (onde fica hermes-agent/)." >&2
  exit 1
fi

cd "$DST"

echo "=> Hermes: $DST"

if ! git apply --check "$COST" 2>/dev/null; then
  echo "AVISO: o patch de custo/saldo não aplica limpo — provável divergência de versão." >&2
  echo "Regenere os patches contra o HEAD atual (ver README do repo, seção de regeneração)." >&2
  exit 1
fi
echo "=> Aplicando patch de custo/saldo..."
git apply "$COST"

if ! git apply --check "$SYS" 2>/dev/null; then
  echo "AVISO: o patch de sysmetrics não aplica limpo após o de custo." >&2
  exit 1
fi
echo "=> Aplicando patch de sysmetrics..."
git apply "$SYS"

echo ""
echo "Instalado. Reinicie o hermes (/quit + hermes) — /new NÃO recarrega o Python."
echo "  1ª linha: ~\$custo + 💰 saldo   (ative: hermes config set display.show_cost true)"
echo "  2ª linha: CPU/RAM/GPU/DISK/E:R (default ON; desligue: hermes config set display.sysmetrics false)"
