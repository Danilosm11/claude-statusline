# Claude Code Status Line

Uma status line colorida para o [Claude Code](https://claude.com/claude-code), para **Linux** e **Windows**.

```
🤖 Opus 5.5 │ 🧠 ━━━━━━━━━━ 22% │ 🪙 45k/200k │ ⏳ 5h 🟢 32% ↻ 08:06 │ 📅 sem 🟠 78% ↻ Dom 22/11 23:13 │ ⏱️ 1h23m
```

| Ícone | O que mostra |
|---|---|
| 🤖 | Modelo em uso |
| 🧠 | Uso da janela de contexto, com barra e % (verde → amarelo 50% → laranja 75% → vermelho 90%) |
| 🪙 | Tokens em uso / tamanho da janela |
| ⏳ | Uso do limite de 5 horas e horário do reset |
| 📅 | Uso do limite semanal e dia/hora do reset |
| ⏱️ | Tempo de sessão |

Os limites de 5h e semanal só aparecem para assinantes do Claude.ai (Pro/Max), depois da primeira resposta da sessão.

## Instalação

### Linux

Requer `bash` e [`jq`](https://jqlang.org/).

```bash
git clone https://github.com/Danilosm11/claude-statusline.git
cd claude-statusline
./install.sh
```

### Windows

Funciona no Windows PowerShell 5.1 e no PowerShell 7. Use o **Windows Terminal** para ver as cores e os emojis.

```powershell
git clone https://github.com/Danilosm11/claude-statusline.git
cd claude-statusline
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Os instaladores copiam o script para `~/.claude/` e adicionam o bloco `statusLine` ao `settings.json`, guardando um backup em `settings.json.bak`. Reinicie o Claude Code depois de instalar.

## Instalação manual

Copie o script para `~/.claude/` e adicione ao `~/.claude/settings.json`:

**Linux**
```json
{
  "statusLine": { "type": "command", "command": "bash ~/.claude/statusline.sh" }
}
```

**Windows**
```json
{
  "statusLine": { "type": "command", "command": "powershell -NoProfile -ExecutionPolicy Bypass -File C:\\Users\\<voce>\\.claude\\statusline.ps1" }
}
```

## Testar

```bash
echo '{"model":{"display_name":"Opus"},"context_window":{"used_percentage":42,"context_window_size":200000,"total_input_tokens":84000},"cost":{"total_duration_ms":600000}}' | bash statusline.sh
```

## Licença

MIT
