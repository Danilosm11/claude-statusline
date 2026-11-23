#!/bin/bash
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "?"')
pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
size=$(echo "$input" | jq -r '.context_window.context_window_size // 0')
used_tok=$(echo "$input" | jq -r '(.context_window.current_usage // {}) as $u | (($u.input_tokens//0)+($u.cache_read_input_tokens//0)+($u.cache_creation_input_tokens//0)) as $c | if $c>0 then $c else (.context_window.total_input_tokens // 0) end')
dur_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // empty')
five=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_r=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_r=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
tp=$(echo "$input" | jq -r '.transcript_path // empty')

if [ -z "$pct" ] && [ "$size" -gt 0 ] 2>/dev/null && [ "$used_tok" -gt 0 ] 2>/dev/null; then
  pct=$(awk -v u="$used_tok" -v s="$size" 'BEGIN{printf "%.1f", u*100/s}')
fi

# Cores vivas (truecolor)
fg() { printf '\033[38;2;%s;%s;%sm' "$1" "$2" "$3"; }
R=$'\033[0m'; B=$'\033[1m'
PINK=$(fg 255 121 198); PURPLE=$(fg 189 147 249); CYAN=$(fg 139 233 253)
GREEN=$(fg 80 250 123); YELLOW=$(fg 241 250 140); ORANGE=$(fg 255 184 108)
RED=$(fg 255 85 85); GRAY=$(fg 98 114 164); BLUE=$(fg 98 174 255)
SEP=" ${GRAY}│${R} "

fmt_tok() {
  awk -v n="$1" 'BEGIN{ if(n>=1000000) printf "%.1fM", n/1000000; else if(n>=1000) printf "%.0fk", n/1000; else printf "%d", n }'
}

color_for() {
  local p=${1%.*}
  if [ "$p" -ge 90 ]; then printf '%s' "$RED"
  elif [ "$p" -ge 75 ]; then printf '%s' "$ORANGE"
  elif [ "$p" -ge 50 ]; then printf '%s' "$YELLOW"
  else printf '%s' "$GREEN"; fi
}

emoji_for() {
  local p=${1%.*}
  if [ "$p" -ge 90 ]; then printf '🔴'
  elif [ "$p" -ge 75 ]; then printf '🟠'
  elif [ "$p" -ge 50 ]; then printf '🟡'
  else printf '🟢'; fi
}

out="🤖 ${B}${PINK}${model}${R}"

# Contexto
if [ -n "$pct" ]; then
  p=$(printf '%.0f' "$pct")
  filled=$((p / 10)); [ $filled -gt 10 ] && filled=10
  col=$(color_for "$p")
  bar=""
  for i in $(seq 1 10); do
    if [ "$i" -le "$filled" ]; then bar="${bar}${col}━"; else bar="${bar}${GRAY}━"; fi
  done
  out="${out}${SEP}🧠 ${bar}${R} ${B}${col}${p}%${R}"
  out="${out}${SEP}🪙 ${CYAN}$(fmt_tok "$used_tok")${GRAY}/${PURPLE}$(fmt_tok "$size")${R}"
else
  out="${out}${SEP}🧠 ${GRAY}--${R}"
fi

# Limites
fmt_date() {
  local dias=(Dom Seg Ter Qua Qui Sex Sáb)
  local f=${2//%a/${dias[$(date -d "@$1" +%w)]}}
  date -d "@$1" +"$f"
}
limit_str() {
  local icon=$1 label=$2 p=$3 r=$4 fmtd=$5
  [ -z "$p" ] && return
  local pi; pi=$(printf '%.0f' "$p")
  local col; col=$(color_for "$pi")
  local s="${icon} ${PURPLE}${label}${R} $(emoji_for "$pi") ${B}${col}${pi}%${R}"
  [ -n "$r" ] && s="${s} ${GRAY}↻${R} ${BLUE}$(fmt_date "$r" "$fmtd")${R}"
  printf '%s' "$s"
}
f=$(limit_str "⏳" "5h" "$five" "$five_r" "%H:%M")
w=$(limit_str "📅" "sem" "$week" "$week_r" "%a %d/%m %H:%M")
[ -n "$f" ] && out="${out}${SEP}${f}"
[ -n "$w" ] && out="${out}${SEP}${w}"

# Tempo de sessão
el=""
if [ -n "$dur_ms" ]; then
  el=$(( ${dur_ms%.*} / 1000 ))
elif [ -n "$tp" ] && [ -f "$tp" ]; then
  start=$(head -n 1 "$tp" | jq -r '.timestamp // empty' 2>/dev/null)
  if [ -n "$start" ]; then s=$(date -d "$start" +%s 2>/dev/null)
  else s=$(stat -c %W "$tp" 2>/dev/null); [ "$s" = "0" ] && s=""; fi
  [ -n "$s" ] && el=$(( $(date +%s) - s ))
fi
if [ -n "$el" ]; then
  [ "$el" -lt 0 ] && el=0
  h=$((el / 3600)); m=$(( (el % 3600) / 60 ))
  if [ $h -gt 0 ]; then t="${h}h${m}m"; else t="${m}m"; fi
  out="${out}${SEP}⏱️ ${ORANGE}${t}${R}"
fi

printf '%s\n' "$out"
