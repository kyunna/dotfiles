#!/bin/bash
input=$(cat)

IFS=$'\t' read -r MODEL DIR PCT DURATION_MS < <(echo "$input" | jq -r '
  [
    .model.display_name,
    .workspace.current_dir,
    (.context_window.used_percentage // 0 | floor),
    (.cost.total_duration_ms // 0)
  ] | @tsv
')

RESET='\033[0m'; GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'

case "$MODEL" in
    *Opus*)   MODEL_COLOR='\033[35m' ;;
    *Sonnet*) MODEL_COLOR='\033[36m' ;;
    *Haiku*)  MODEL_COLOR="$GREEN"   ;;
    *)        MODEL_COLOR='\033[37m' ;;
esac

if   [ "$PCT" -ge 90 ]; then BAR_COLOR="$RED"
elif [ "$PCT" -ge 70 ]; then BAR_COLOR="$YELLOW"
else                         BAR_COLOR="$GREEN"; fi

FILLED=$((PCT / 10)); EMPTY=$((10 - FILLED))
printf -v FILLED_PART "%${FILLED}s"
printf -v EMPTY_PART "%${EMPTY}s"
BAR="${FILLED_PART// /█}${EMPTY_PART// /░}"

MINS=$((DURATION_MS / 60000))
SECS=$(((DURATION_MS % 60000) / 1000))

BRANCH=""
git -C "$DIR" rev-parse --git-dir &>/dev/null \
  && BRANCH=" | 🌿 $(git branch --show-current 2>/dev/null)"

echo -e "${MODEL_COLOR}🐬 ${MODEL}${RESET} | 📁 ${DIR##*/}$BRANCH | ${BAR_COLOR}${BAR}${RESET} ${PCT}% | ⏱️ ${MINS}m ${SECS}s"
