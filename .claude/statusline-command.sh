#!/usr/bin/env bash
# Claude Code statusLine command — derived from ~/.bashrc PS1
# Local-only: spends no tokens / API / plan-usage. Kept cheap by extracting
# every JSON field in a SINGLE jq pass (this runs on every status refresh).

input=$(cat)

# One jq call. Join with the ASCII Unit Separator (0x1F), NOT a tab: `read`
# treats tab as IFS-whitespace and COLLAPSES an empty field (e.g. a null
# rate-limit right after /clear), shifting every later value left by one. 0x1F
# is non-whitespace, so empty fields are preserved and alignment holds.
IFS=$'\037' read -r cwd model ctx cost five five_reset seven seven_reset added removed effort < <(
    printf '%s' "$input" | jq -r '
        [ .cwd,
          .model.display_name,
          .context_window.used_percentage,
          .cost.total_cost_usd,
          .rate_limits.five_hour.used_percentage,
          .rate_limits.five_hour.resets_at,
          .rate_limits.seven_day.used_percentage,
          .rate_limits.seven_day.resets_at,
          .cost.total_lines_added,
          .cost.total_lines_removed,
          .effort.level
        ] | map(. // "" | tostring) | join("")'
)
[ -z "$cwd" ] && cwd=$(pwd)
dir_name=$(basename "$cwd")

# ANSI colors (appear dimmed in Claude's status bar)
txtcyn="\e[36m"
txtred="\e[31m"
txtylw="\e[33m"
txtrst="\e[0m"

# Git branch, dirty flag, and ahead/behind the upstream (↑ unpushed, ↓ unpulled)
git_branch=""
git_dirty=""
git_ab=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
             || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
    [ -n "$branch" ] && git_branch="$branch "
    [ -n "$(git -C "$cwd" status --porcelain 2>/dev/null)" ] && git_dirty="*"
    if ab=$(git -C "$cwd" rev-list --left-right --count '@{u}...HEAD' 2>/dev/null); then
        read -r behind ahead <<< "$ab"
        [ "${ahead:-0}" -gt 0 ] && git_ab="${git_ab}↑${ahead}"
        [ "${behind:-0}" -gt 0 ] && git_ab="${git_ab}↓${behind}"
    fi
fi

# dir + git only (dropped user@host — constant on a personal machine)
printf "%s %b%s%b%s%b%s%b" \
    "$dir_name" \
    "$txtcyn" "$git_branch" \
    "$txtred" "$git_dirty" \
    "$txtylw" "$git_ab" \
    "$txtrst"

# --- Primary agent: model · context% · cost · plan usage ---
# cost.total_cost_usd is the session aggregate (rolls up subagent spend).
txtdim="\e[2m"
# Threshold colors for usage %s (scheme B: green<65 / yellow / red>=90).
# Real ESC bytes ($'...') so they survive %s printing of $seg below.
c_rst=$'\033[0m'; c_dim=$'\033[2m'; c_lo=$'\033[32m'; c_md=$'\033[33m'; c_hi=$'\033[31m'
pctcol() {  # $1 = integer percent -> emit the severity color
    if   [ "$1" -ge 90 ]; then printf '%s' "$c_hi"
    elif [ "$1" -ge 65 ]; then printf '%s' "$c_md"
    else printf '%s' "$c_lo"; fi
}
# Session-scoped group: model · context% · cost · lines · effort
sess=""
[ -n "$model" ] && sess="${model%% (*}"   # strip "(1M context)" suffix
if [ -n "$ctx" ]; then
    ctx_i=$(printf '%.0f' "$ctx" 2>/dev/null)
    [ -n "$ctx_i" ] && sess="${sess:+$sess }$(pctcol "$ctx_i")${ctx_i}%${c_rst}"
fi
if [ -n "$cost" ]; then
    cost_f=$(printf '$%.2f' "$cost" 2>/dev/null)
    [ -n "$cost_f" ] && sess="${sess:+$sess }${cost_f}"
fi
# Session code churn: +added/-removed (green/red), only when non-zero
if { [ "${added:-0}" -gt 0 ] || [ "${removed:-0}" -gt 0 ]; } 2>/dev/null; then
    sess="${sess:+$sess }${c_lo}+${added:-0}${c_rst}/${c_hi}-${removed:-0}${c_rst}"
fi
# Reasoning effort level (e.g. high / xhigh)
[ -n "$effort" ] && sess="${sess:+$sess }${c_dim}⚡${effort}${c_rst}"
# Bracket the session trio (dim brackets) to set it apart from the
# account-scoped plan usage, which stays OUTSIDE the brackets.
seg=""
[ -n "$sess" ] && seg="${c_dim}[${c_rst}${sess}${c_dim}]${c_rst}"
# Plan usage: 5-hour and 7-day rate-limit windows (absent on API billing → skipped)
if [ -n "$five" ]; then
    five_i=$(printf '%.0f' "$five" 2>/dev/null)
    plan="5h $(pctcol "$five_i")${five_i}%${c_rst}"
    rtime=$(date -r "$five_reset" +%H:%M 2>/dev/null)
    [ -n "$rtime" ] && plan="${plan} ↻${rtime}"
    if [ -n "$seven" ]; then
        seven_i=$(printf '%.0f' "$seven" 2>/dev/null)
        plan="${plan} · 7d $(pctcol "$seven_i")${seven_i}%${c_rst}"
        # 7d window is days out → show a date (↻Aug 2), not a clock time.
        dtime=$(date -r "$seven_reset" "+%b %-d" 2>/dev/null || date -r "$seven_reset" "+%b %d" 2>/dev/null)
        [ -n "$dtime" ] && plan="${plan} ↻${dtime}"
    fi
    seg="${seg:+$seg }${plan}"
fi
[ -n "$seg" ] && printf " %b·%b %s" "$txtdim" "$txtrst" "$seg"
