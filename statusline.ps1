# Claude Code status line - Windows (PowerShell 5.1+ / PowerShell 7)
# Arquivo mantido em ASCII puro: emojis sao gerados por codepoint para funcionar no PowerShell 5.1.

[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$raw = [Console]::In.ReadToEnd()
try { $j = $raw | ConvertFrom-Json } catch { Write-Output "Claude"; exit 0 }

function E([int]$cp) { [char]::ConvertFromUtf32($cp) }
$ESC = [char]27
function Fg($r, $g, $b) { "$ESC[38;2;${r};${g};${b}m" }
$R = "$ESC[0m"; $B = "$ESC[1m"
$PINK = Fg 255 121 198; $PURPLE = Fg 189 147 249; $CYAN = Fg 139 233 253
$GREEN = Fg 80 250 123; $YELLOW = Fg 241 250 140; $ORANGE = Fg 255 184 108
$RED = Fg 255 85 85; $GRAY = Fg 98 114 164; $BLUE = Fg 98 174 255
$SEP = " $GRAY$([char]0x2502)$R "

function ColorFor([double]$p) {
  if ($p -ge 90) { $RED } elseif ($p -ge 75) { $ORANGE } elseif ($p -ge 50) { $YELLOW } else { $GREEN }
}
function DotFor([double]$p) {
  if ($p -ge 90) { E 0x1F534 } elseif ($p -ge 75) { E 0x1F7E0 } elseif ($p -ge 50) { E 0x1F7E1 } else { E 0x1F7E2 }
}
function FmtTok([double]$n) {
  if ($n -ge 1000000) { '{0:0.0}M' -f ($n / 1000000) }
  elseif ($n -ge 1000) { '{0:0}k' -f ($n / 1000) }
  else { '{0:0}' -f $n }
}
function Get-Val($obj, [string[]]$path) {
  foreach ($k in $path) { if ($null -eq $obj) { return $null }; $obj = $obj.$k }
  return $obj
}

$model = Get-Val $j 'model','display_name'; if (-not $model) { $model = '?' }
$size  = [double](Get-Val $j 'context_window','context_window_size')
$pct   = Get-Val $j 'context_window','used_percentage'
$u     = Get-Val $j 'context_window','current_usage'
$used  = 0.0
if ($u) { $used = [double]$u.input_tokens + [double]$u.cache_read_input_tokens + [double]$u.cache_creation_input_tokens }
if ($used -le 0) { $used = [double](Get-Val $j 'context_window','total_input_tokens') }
if ($null -eq $pct -and $size -gt 0 -and $used -gt 0) { $pct = $used * 100 / $size }

$out = "$(E 0x1F916) $B$PINK$model$R"

# Contexto
if ($null -ne $pct) {
  $p = [math]::Round([double]$pct)
  $filled = [math]::Min(10, [math]::Floor($p / 10))
  $col = ColorFor $p
  $line = [string][char]0x2501
  $bar = ''
  for ($i = 1; $i -le 10; $i++) { if ($i -le $filled) { $bar += "$col$line" } else { $bar += "$GRAY$line" } }
  $out += "$SEP$(E 0x1F9E0) $bar$R $B$col$p%$R"
  $out += "$SEP$(E 0x1FA99) $CYAN$(FmtTok $used)$GRAY/$PURPLE$(FmtTok $size)$R"
} else {
  $out += "$SEP$(E 0x1F9E0) $GRAY--$R"
}

# Limites
$dias = @('Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', "S$([char]0xE1)b")
function LimitStr($icon, $label, $lim, [bool]$withDay) {
  if ($null -eq $lim -or $null -eq $lim.used_percentage) { return $null }
  $p = [math]::Round([double]$lim.used_percentage)
  $col = ColorFor $p
  $s = "$icon $PURPLE$label$R $(DotFor $p) $B$col$p%$R"
  if ($lim.resets_at) {
    $d = [DateTimeOffset]::FromUnixTimeSeconds([long]$lim.resets_at).LocalDateTime
    if ($withDay) { $t = "$($dias[[int]$d.DayOfWeek]) $($d.ToString('dd/MM HH:mm'))" } else { $t = $d.ToString('HH:mm') }
    $s += " $GRAY$([char]0x21BB)$R $BLUE$t$R"
  }
  return $s
}
$f = LimitStr (E 0x23F3) '5h'  (Get-Val $j 'rate_limits','five_hour') $false
$w = LimitStr (E 0x1F4C5) 'sem' (Get-Val $j 'rate_limits','seven_day') $true
if ($f) { $out += "$SEP$f" }
if ($w) { $out += "$SEP$w" }

# Tempo de sessao
$ms = Get-Val $j 'cost','total_duration_ms'
if ($null -ne $ms) {
  $el = [math]::Floor([double]$ms / 1000)
  $h = [math]::Floor($el / 3600); $m = [math]::Floor(($el % 3600) / 60)
  if ($h -gt 0) { $t = "${h}h${m}m" } else { $t = "${m}m" }
  $out += "$SEP$(E 0x23F1)$([char]0xFE0F) $ORANGE$t$R"
}

[Console]::Out.Write($out + "`n")
