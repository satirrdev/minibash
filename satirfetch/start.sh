#!/data/data/com.termux/files/usr/bin/bash

BASE_DIR="$HOME/.local/share/satirfetch"
CONFIG="$BASE_DIR/config.conf"

mkdir -p "$BASE_DIR"

if [ ! -f "$CONFIG" ]; then
    echo "Config tidak ditemukan:"
    echo "$CONFIG"
    exit 1
fi

source "$CONFIG"

# ==========================================
# COLORS
# ==========================================

reset="\033[0m"

red="\033[1;31m"
green="\033[1;32m"
yellow="\033[1;33m"
blue="\033[1;34m"
magenta="\033[1;35m"
cyan="\033[1;36m"
white="\033[1;37m"
gray="\033[1;30m"

trace_none="\033[38;5;255m"

trace_1="\033[38;5;120m"
trace_2="\033[38;5;84m"
trace_3="\033[38;5;78m"
trace_4="\033[38;5;35m"
trace_5="\033[38;5;22m"

cl1="$red"
cl2="$green"
cl3="$yellow"
cl4="$blue"
cl5="$magenta"
cl6="$cyan"
cl7="$white"

CL_INDEX=(
    "$cl1"
    "$cl2"
    "$cl3"
    "$cl4"
    "$cl5"
    "$cl6"
    "$cl7"
)

# ==========================================
# FILES
# ==========================================

ACTIVITY_FILE="$BASE_DIR/activity.log"
SESSION_START="$BASE_DIR/session.start"
SESSION_LAST="$BASE_DIR/session.last"

touch "$ACTIVITY_FILE"

TODAY="$(date '+%Y-%m-%d')"
NOW="$(date '+%s')"

# ==========================================
# SESSION TRACKING
# ==========================================

update_activity() {

    [ ! -f "$SESSION_START" ] && return

    local start
    local last
    local delta

    start="$(cat "$SESSION_START" 2>/dev/null)"
    last="$(cat "$SESSION_LAST" 2>/dev/null)"

    [[ "$start" =~ ^[0-9]+$ ]] || return

    if [[ "$last" =~ ^[0-9]+$ ]]; then
        delta=$((NOW - last))
    else
        delta=$((NOW - start))
    fi

    # Ignore impossible values
    if [ "$delta" -lt 0 ]; then
        delta=0
    fi

    # Prevent one broken/stale session from adding absurd time
    if [ "$delta" -gt 14400 ]; then
        delta=14400
    fi

    local current

    current="$(
        awk -v d="$TODAY" '$1 == d {print $2; found=1} END {if (!found) print 0}' \
        "$ACTIVITY_FILE"
    )"

    [[ "$current" =~ ^[0-9]+$ ]] || current=0

    current=$((current + delta))

    awk -v d="$TODAY" -v t="$current" '
        $1 != d {print}
        END {print d, t}
    ' "$ACTIVITY_FILE" > "$ACTIVITY_FILE.tmp"

    mv "$ACTIVITY_FILE.tmp" "$ACTIVITY_FILE"

    printf "%s\n" "$NOW" > "$SESSION_LAST"
}

update_activity

# ==========================================
# SYSTEM INFO
# ==========================================

distro="Android"

android="$(getprop ro.build.version.release 2>/dev/null)"
sdk="$(getprop ro.build.version.sdk 2>/dev/null)"

[ -n "$android" ] && distro="Android $android"

kernel="$(uname -r 2>/dev/null)"
[ -z "$kernel" ] && kernel="?"

arch="$(uname -m 2>/dev/null)"
[ -z "$arch" ] && arch="?"

shell="${SHELL##*/}"
[ -z "$shell" ] && shell="bash"

if [ "$shell" = "bash" ]; then
    shell="bash ${BASH_VERSION%%(*}"
fi

packages="?"

if command -v dpkg-query >/dev/null 2>&1; then
    packages="$(dpkg-query -W 2>/dev/null | wc -l)"
fi

wm="Termux"

# ==========================================
# MEMORY
# ==========================================

memory_total="$(
    awk '/MemTotal/ {
        printf "%.1fG", $2 / 1024 / 1024
    }' /proc/meminfo 2>/dev/null
)"

memory_available="$(
    awk '/MemAvailable/ {
        printf "%.1fG", $2 / 1024 / 1024
    }' /proc/meminfo 2>/dev/null
)"

if [ -n "$memory_total" ] && [ -n "$memory_available" ]; then
    memory="$memory_available/$memory_total"
else
    memory="?"
fi

# ==========================================
# UPTIME
# ==========================================

uptime_info="$(
    uptime 2>/dev/null |
    sed 's/.*up //' |
    sed 's/, [0-9]* users.*//' |
    sed 's/,  load.*//'
)"

[ -z "$uptime_info" ] && uptime_info="?"

# ==========================================
# TERMUX
# ==========================================

termux_version="${TERMUX_VERSION:-?}"

# ==========================================
# TODAY ACTIVITY
# ==========================================

today_seconds="$(
    awk -v d="$TODAY" '$1 == d {print $2}' "$ACTIVITY_FILE"
)"

[[ "$today_seconds" =~ ^[0-9]+$ ]] || today_seconds=0

today_minutes=$((today_seconds / 60))

if [ "$today_minutes" -lt 60 ]; then
    today_duration="${today_minutes}m"
else
    today_hours=$((today_minutes / 60))
    today_mins=$((today_minutes % 60))

    if [ "$today_mins" -eq 0 ]; then
        today_duration="${today_hours}h"
    else
        today_duration="${today_hours}h ${today_mins}m"
    fi
fi

# ==========================================
# STREAK
# ==========================================

get_activity() {
    awk -v d="$1" '$1 == d {print $2}' "$ACTIVITY_FILE"
}

streak=0
check_date="$TODAY"

while true; do

    value="$(get_activity "$check_date")"

    [[ "$value" =~ ^[0-9]+$ ]] || value=0

    if [ "$value" -le 0 ]; then
        break
    fi

    streak=$((streak + 1))

    check_date="$(
        date -d "$check_date - 1 day" '+%Y-%m-%d' 2>/dev/null
    )"

    [ -z "$check_date" ] && break

done

# ==========================================
# ACTIVE TRACE
# ==========================================

trace_symbol() {
    local seconds="$1"
    local minutes=$((seconds / 60))

    if [ "$minutes" -le 0 ]; then
        printf "%b·%b" "$trace_none" "$reset"

    elif [ "$minutes" -le 15 ]; then
        printf "%b󰇙%b" "$trace_1" "$reset"

    elif [ "$minutes" -le 30 ]; then
        printf "%b󰇚%b" "$trace_2" "$reset"

    elif [ "$minutes" -le 45 ]; then
        printf "%b󰇛%b" "$trace_3" "$reset"

    elif [ "$minutes" -lt 60 ]; then
        printf "%b󰇜%b" "$trace_4" "$reset"

    else
        printf "%b󰇜%b" "$trace_5" "$reset"
    fi
}

TRACE_LINES=()

if [ "$SHOW_TRACE" = true ]; then

    # Last TRACE_DAYS days
    for ((i=TRACE_DAYS-1; i>=0; i--)); do

        day="$(
            date -d "$TODAY - $i day" '+%Y-%m-%d' 2>/dev/null
        )"

        seconds="$(get_activity "$day")"
        [[ "$seconds" =~ ^[0-9]+$ ]] || seconds=0

        symbol="$(trace_symbol "$seconds")"

        TRACE_LINES+=("$symbol")

    done

fi

# ==========================================
# INFORMATION
# ==========================================

INFO_LINES=()

[ "$SHOW_DISTRO" = true ] &&
    INFO_LINES+=("󰀄  $distro")

[ "$SHOW_KERNEL" = true ] &&
    INFO_LINES+=("󰒓  $kernel")

[ "$SHOW_ARCH" = true ] &&
    INFO_LINES+=("󰘚  $arch")

[ "$SHOW_PACKAGES" = true ] &&
    INFO_LINES+=("󰏖  $packages pkgs")

[ "$SHOW_SHELL" = true ] &&
    INFO_LINES+=("󰆍  $shell")

[ "$SHOW_WM" = true ] &&
    INFO_LINES+=("󰖲  $wm")

[ "$SHOW_MEMORY" = true ] &&
    INFO_LINES+=("󰍛  $memory")

[ "$SHOW_UPTIME" = true ] &&
    INFO_LINES+=("󰅐  $uptime_info")

[ "$SHOW_TERMUX" = true ] &&
    INFO_LINES+=("󰆍  T $termux_version")

[ "$SHOW_ANDROID" = true ] && [ -n "$sdk" ] &&
    INFO_LINES+=("󰒓  SDK $sdk")

[ "$SHOW_TIME" = true ] &&
    INFO_LINES+=("󰥔  $(date '+%H:%M:%S' 2>/dev/null)")

# ==========================================
# ASCII
# ==========================================

ASCII_LINES=(
"      .----------------."
"     |          _       |"
"     |      _.-'|'-._   |"
"     | .__.|    |    |  |"
"     |     |_.-'|'-._|  |"
"     | '--'|    |    |  |"
"     | '--'|_.-'\`'-._|  |"
"  tmx| '--'          \`  |"
"      '----------------'"
)

# ==========================================
# IMAGE
# ==========================================

USE_IMAGE=false

if [ "$SHOW_IMAGE" = true ] &&
   [ -f "$IMAGE_PATH" ] &&
   command -v viu >/dev/null 2>&1; then
    USE_IMAGE=true
fi

print_left() {

    if [ "$USE_IMAGE" = true ]; then

        viu \
            -w "$IMAGE_WIDTH" \
            -h "$IMAGE_HEIGHT" \
            "$IMAGE_PATH" 2>/dev/null

        return
    fi

    printf "%s\n" "${ASCII_LINES[@]}"
}

# ==========================================
# CAPTURE LEFT
# ==========================================

LEFT_OUTPUT="$(print_left)"

LEFT_LINES=()

while IFS= read -r line; do
    LEFT_LINES+=("$line")
done <<< "$LEFT_OUTPUT"

LEFT_COUNT=${#LEFT_LINES[@]}
INFO_COUNT=${#INFO_LINES[@]}

if [ "$LEFT_COUNT" -gt "$INFO_COUNT" ]; then
    TOTAL_LINES="$LEFT_COUNT"
else
    TOTAL_LINES="$INFO_COUNT"
fi

# ==========================================
# OUTPUT
# ==========================================

clear

for ((i=0; i<TOTAL_LINES; i++)); do

    left=""
    right=""

    [ "$i" -lt "$LEFT_COUNT" ] &&
        left="${LEFT_LINES[$i]}"

    [ "$i" -lt "$INFO_COUNT" ] &&
        right="${INFO_LINES[$i]}"

    color="${CL_INDEX[$((i % 7))]}"

    printf "%-30s  %b%s%b\n" \
        "$left" \
        "$color" \
        "$right" \
        "$reset"

done

# ==========================================
# ACTIVE TRACE
# ==========================================

if [ "$SHOW_TRACE" = true ]; then

    printf "\n"
    printf "%bActive Trace%b\n" "$cyan" "$reset"
    printf " "

    for symbol in "${TRACE_LINES[@]}"; do
        printf " %s" "$symbol"
    done

    printf "\n"
    printf " %b%s%b\n" "$gray" "$TRACE_DAYS days" "$reset"

fi

# ==========================================
# CURRENT STREAK
# ==========================================

if [ "$SHOW_STREAK" = true ]; then

    printf "\n"

    if [ "$streak" -eq 1 ]; then
        streak_text="Current Streak is 1 day"
    else
        streak_text="Current Streak is $streak days"
    fi

    printf "%b%s%b\n" "$green" "$streak_text" "$reset"
    printf "%bKeep it Up!%b\n" "$gray" "$reset"

fi

# ==========================================
# TODAY
# ==========================================

if [ "$SHOW_TODAY" = true ]; then
    printf "%bToday: %s%b\n" "$gray" "$today_duration" "$reset"
fi

printf "\n"

exit 0