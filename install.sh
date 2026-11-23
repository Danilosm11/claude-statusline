#!/usr/bin/env bash
# Instala a status line no Claude Code (Linux / macOS com GNU date)
set -euo pipefail

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$CLAUDE_DIR/statusline.sh"
SETTINGS="$CLAUDE_DIR/settings.json"

command -v jq >/dev/null || { echo "Erro: instale o jq primeiro (ex.: sudo apt install jq / sudo pacman -S jq)"; exit 1; }

mkdir -p "$CLAUDE_DIR"
cp "$SRC_DIR/statusline.sh" "$DEST"
chmod +x "$DEST"

[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
cp "$SETTINGS" "$SETTINGS.bak"
tmp=$(mktemp)
jq --arg cmd "bash $DEST" '.statusLine = {type: "command", command: $cmd}' "$SETTINGS" > "$tmp"
mv "$tmp" "$SETTINGS"

echo "Status line instalada em $DEST"
echo "settings.json atualizado (backup em $SETTINGS.bak). Reinicie o Claude Code."
