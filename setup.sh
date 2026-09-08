# 1. Pastikan default shell Termux adalah bash
chsh -s bash 2>/dev/null || true

# 2. Siapkan folder
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.local/share/minibash"
touch "$HOME/.local/share/minibash/activity.log"

# Migrasi data log lama kalau ada biar streak nggak reset ke 0
if [ -f "$HOME/.local/share/satirfetch/activity.log" ]; then
    cat "$HOME/.local/share/satirfetch/activity.log" >> "$HOME/.local/share/minibash/activity.log"
    sort -u "$HOME/.local/share/minibash/activity.log" -o "$HOME/.local/share/minibash/activity.log"
    rm -rf "$HOME/.local/share/satirfetch" "$HOME/.local/bin/satirfetch" 2>/dev/null
fi

# 3. Deploy binary minifetch
cat << 'EOF' > "$HOME/.local/bin/minifetch"
#!/data/data/com.termux/files/usr/bin/bash

LOG_FILE="$HOME/.local/share/minibash/activity.log"

calc_streak() {
    [ ! -f "$LOG_FILE" ] && echo 0 && return

    local dates
    dates=($(awk '{print $1}' "$LOG_FILE" | sort -ru))
    [ ${#dates[@]} -eq 0 ] && echo 0 && return

    local today yesterday
    today="$(date '+%Y-%m-%d')"
    yesterday="$(date -d "yesterday" '+%Y-%m-%d' 2>/dev/null || date -v-1d '+%Y-%m-%d')"

    if [ "${dates[0]}" != "$today" ] && [ "${dates[0]}" != "$yesterday" ]; then
        echo 0
        return
    fi

    local streak=1
    local prev_epoch
    prev_epoch="$(date -d "${dates[0]}" '+%s' 2>/dev/null || date -j -f "%Y-%m-%d" "${dates[0]}" '+%s')"

    for ((i=1; i<${#dates[@]}; i++)); do
        local curr_epoch diff_days
        curr_epoch="$(date -d "${dates[$i]}" '+%s' 2>/dev/null || date -j -f "%Y-%m-%d" "${dates[$i]}" '+%s')"
        diff_days=$(( (prev_epoch - curr_epoch) / 86400 ))

        if [ "$diff_days" -eq 1 ]; then
            streak=$((streak + 1))
            prev_epoch="$curr_epoch"
        else
            break
        fi
    done

    echo "$streak"
}

C_RESET='\033[0m'
C_CYAN='\033[1;36m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_GRAY='\033[1;30m'

UPTIME="$(uptime -p 2>/dev/null | sed 's/up //')"
[ -z "$UPTIME" ] && UPTIME="just started"

PKGS="$(dpkg-query -l 2>/dev/null | grep -c '^ii')"
SHELL_NAME="$(basename "$SHELL")"
STREAK="$(calc_streak)"

TODAY_DATE="$(date '+%Y-%m-%d')"
TODAY_SECS="$(awk -v d="$TODAY_DATE" '$1 == d {print $2}' "$LOG_FILE")"
TODAY_MINS=$(( ${TODAY_SECS:-0} / 60 ))

printf "\n"
printf "${C_CYAN}  _  _  _       ${C_RESET}   ${C_CYAN}USER${C_RESET}     : $(whoami)\n"
printf "${C_CYAN} | \/ |(_)_     ${C_RESET}   ${C_CYAN}OS${C_RESET}       : Termux (Android $(getprop ro.build.version.release 2>/dev/null))\n"
printf "${C_CYAN} |_||_| | |     ${C_RESET}   ${C_CYAN}UPTIME${C_RESET}   : ${UPTIME}\n"
printf "${C_CYAN}                ${C_RESET}   ${C_CYAN}PKGS${C_RESET}     : ${PKGS}\n"
printf "${C_CYAN}  [MiniBash]    ${C_RESET}   ${C_CYAN}SHELL${C_RESET}    : ${SHELL_NAME}\n"
printf "                    ${C_YELLOW}STREAK${C_RESET}   : ${C_GREEN}${STREAK} days 🔥${C_RESET}\n"
printf "                    ${C_YELLOW}SESSION${C_RESET}  : ${TODAY_MINS} mins today\n"
printf "\n"
EOF

chmod +x "$HOME/.local/bin/minifetch"

# 4. Tulis langsung ke ~/.bashrc bawaan
cat << 'EOF' > "$HOME/.bashrc"
# ==========================================================
#                   MINIBASH TERMUX BASHRC
# ==========================================================

export PATH="$HOME/.local/bin:$PATH"

RESET='\033[0m'
BOLD='\033[1m'
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
GRAY='\033[1;30m'

# Auto-install dependencies
if [[ $- == *i* ]]; then
    REQUIRED_PKGS=(tmux mpv yt-dlp cava pulseaudio proot-distro)
    MISSING_PKGS=()

    for pkg in "${REQUIRED_PKGS[@]}"; do
        if ! command -v "$pkg" >/dev/null 2>&1; then
            MISSING_PKGS+=("$pkg")
        fi
    done

    if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
        printf "\n${YELLOW}[!] Paket belum lengkap: ${MISSING_PKGS[*]}${RESET}\n"
        printf "${CYAN}Menginstall paket yang kurang...${RESET}\n\n"
        pkg update -y && pkg install -y "${MISSING_PKGS[@]}"
        printf "\n${GREEN}✓ Semua dependensi beres diinstall.${RESET}\n\n"
    fi
fi

# Session tracker
MINIBASH_DIR="$HOME/.local/share/minibash"
mkdir -p "$MINIBASH_DIR"
MINIBASH_SESSION="$MINIBASH_DIR/session.start"
MINIBASH_LAST="$MINIBASH_DIR/session.last"
MINIBASH_ACTIVITY="$MINIBASH_DIR/activity.log"
touch "$MINIBASH_ACTIVITY"

if [[ $- == *i* ]] && [ -z "$MINIBASH_SESSION_ACTIVE" ]; then
    export MINIBASH_SESSION_ACTIVE=1
    date '+%s' > "$MINIBASH_SESSION"
    date '+%s' > "$MINIBASH_LAST"

    minibash_session_update() {
        local now last delta today current file
        now="$(date '+%s')"
        last="$(cat "$MINIBASH_LAST" 2>/dev/null)"

        if [[ "$last" =~ ^[0-9]+$ ]]; then
            delta=$((now - last))
            if [ "$delta" -gt 0 ] && [ "$delta" -lt 14400 ]; then
                today="$(date '+%Y-%m-%d')"
                file="$MINIBASH_ACTIVITY"
                current="$(awk -v d="$today" '$1 == d {print $2}' "$file")"
                [[ "$current" =~ ^[0-9]+$ ]] || current=0
                current=$((current + delta))

                awk -v d="$today" -v t="$current" '
                    $1 != d {print}
                    END {print d, t}
                ' "$file" > "$file.tmp"
                mv "$file.tmp" "$file"
            fi
        fi
        printf '%s\n' "$now" > "$MINIBASH_LAST"
    }
    trap 'minibash_session_update' EXIT
fi

# Boot sequence
if [[ $- == *i* ]] && [ -z "$MINIBASH_BOOTED" ]; then
    export MINIBASH_BOOTED=1
    clear
    printf "\n${CYAN}${BOLD}Booting MiniBash...${RESET}\n\n"

    boot_ok() {
        printf "${WHITE}Starting %-30s${RESET} [${GREEN} OK ${RESET}]\n" "$1"
        sleep 0.05
    }

    boot_ok "Termux environment"
    boot_ok "Filesystem"
    boot_ok "Device manager"
    boot_ok "Network manager"
    boot_ok "Audio server"
    boot_ok "Terminal services"
    boot_ok "Shell environment"
    boot_ok "Session tracker"

    printf "\n${GREEN}${BOLD}System initialization complete.${RESET}\n"
    sleep 0.15

    if command -v minifetch >/dev/null 2>&1; then
        minifetch
    fi
fi

# Random MOTD
MOTDS=(
    "System ready. Humanity remains questionable."
    "All services started. Somehow."
    "Welcome back, operator."
    "System online."
    "Everything appears to be working."
    "No critical errors detected. Suspicious."
    "Terminal initialized successfully."
    "Boot completed. Please do not break anything."
    "Another day, another shell."
    "The machine lives."
    "Keep building."
    "Less noise. More code."
    "Read the error message."
    "Automation beats repetition."
    "Knowledge compounds."
    "Build something useful."
)
RANDOM_MOTD="${MOTDS[$RANDOM % ${#MOTDS[@]}]}"
printf "${GRAY}%s${RESET}\n\n" "$RANDOM_MOTD"

# Aliases
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'
alias c='clear'
alias cls='clear'
alias ..='cd ..'
alias ...='cd ../..'
alias update='pkg update && pkg upgrade'
alias reload='source ~/.bashrc'
alias debian='proot-distro login debian'

helpme() {
    printf "\n${CYAN}${BOLD}MiniBash Commands${RESET}\n"
    printf "${GRAY}────────────────────────────────────${RESET}\n"
    printf "${GREEN}ll${RESET}              Detailed file list\n"
    printf "${GREEN}la${RESET}              Show hidden files\n"
    printf "${GREEN}l${RESET}               Compact file list\n"
    printf "${GREEN}c${RESET}               Clear terminal\n"
    printf "${GREEN}update${RESET}          Update Termux\n"
    printf "${GREEN}reload${RESET}          Reload .bashrc\n"
    printf "${GREEN}debian${RESET}          Enter Debian\n"
    printf "${GREEN}minifetch${RESET}      System information & Streak\n"
    printf "${GREEN}music${RESET}           Music player\n"
    printf "${GREEN}music --landscape${RESET}  Music + CAVA landscape\n"
    printf "${GREEN}music -r${RESET}       Discover from music history\n"
    printf "${GREEN}music -h${RESET}       Show music history\n"
    printf "${GREEN}music -c${RESET}       Clear music history\n"
    printf "${GREEN}poweroff${RESET}       Shut down Termux\n\n"
}

poweroff() {
    printf "\n${YELLOW}${BOLD}Shutting down MiniBash...${RESET}\n\n"
    printf "${WHITE}Stopping music player${RESET} [${GREEN} OK ${RESET}]\n"
    pkill -TERM mpv 2>/dev/null
    printf "${WHITE}Stopping visualizer${RESET} [${GREEN} OK ${RESET}]\n"
    pkill -TERM cava 2>/dev/null
    printf "${WHITE}Stopping audio server${RESET} [${GREEN} OK ${RESET}]\n"
    pulseaudio --kill 2>/dev/null
    printf "${WHITE}Stopping tmux${RESET} [${GREEN} OK ${RESET}]\n"
    tmux kill-server 2>/dev/null
    sleep 0.2
    printf "\n${GREEN}${BOLD}System halted.${RESET}\n"
    sleep 0.2
    am force-stop com.termux 2>/dev/null
    exit
}

# Music player
music() {
    local LANDSCAPE=false RANDOM_MODE=false HISTORY_MODE=false CLEAR_MODE=false
    local MUSIC_DIR="$HOME/.local/share/minibash"
    local MUSIC_HISTORY="$MUSIC_DIR/music_history"
    local MUSIC_HISTORY_MAX=10

    mkdir -p "$MUSIC_DIR"
    touch "$MUSIC_HISTORY"

    while [ $# -gt 0 ]; do
        case "$1" in
            --landscape) LANDSCAPE=true; shift ;;
            -r|--random) RANDOM_MODE=true; shift ;;
            -h|--history) HISTORY_MODE=true; shift ;;
            -c|--clear) CLEAR_MODE=true; shift ;;
            *) break ;;
        esac
    done

    music_history_add() {
        local SONG="$1"
        [ -z "$SONG" ] && return
        SONG="$(printf '%s' "$SONG" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        [ -z "$SONG" ] && return
        grep -Fvx "$SONG" "$MUSIC_HISTORY" > "$MUSIC_HISTORY.tmp" 2>/dev/null
        printf '%s\n' "$SONG" >> "$MUSIC_HISTORY.tmp"
        tail -n "$MUSIC_HISTORY_MAX" "$MUSIC_HISTORY.tmp" > "$MUSIC_HISTORY"
        rm -f "$MUSIC_HISTORY.tmp"
    }

    music_history_show() {
        if [ ! -s "$MUSIC_HISTORY" ]; then
            printf "${YELLOW}Music history masih kosong.${RESET}\n"
            return
        fi
        printf "\n${CYAN}${BOLD}╭──────────────────────────────╮${RESET}\n"
        printf "${CYAN}${BOLD}│       MUSIC HISTORY          │${RESET}\n"
        printf "${CYAN}${BOLD}╰──────────────────────────────╯${RESET}\n"
        local INDEX=1
        while IFS= read -r SONG; do
            printf "${YELLOW}%2d${RESET}  %s\n" "$INDEX" "$SONG"
            INDEX=$((INDEX + 1))
        done < "$MUSIC_HISTORY"
        printf "\n"
    }

    music_history_clear() {
        : > "$MUSIC_HISTORY"
        printf "${GREEN}✓ Music history cleared.${RESET}\n"
    }

    if [ "$CLEAR_MODE" = true ]; then music_history_clear; return; fi
    if [ "$HISTORY_MODE" = true ]; then music_history_show; return; fi

    if [ -z "$TMUX" ]; then
        printf "${RED}Error: Fungsi music wajib dijalankan di dalam sesi tmux!${RESET}\n"
        return 1
    fi

    printf "\n${CYAN}${BOLD}╭──────────────────────────────╮${RESET}\n"
    printf "${CYAN}${BOLD}│        MUSIC PLAYER          │${RESET}\n"
    printf "${CYAN}${BOLD}╰──────────────────────────────╯${RESET}\n"

    if [ "$LANDSCAPE" = true ]; then
        tmux split-window -h -p 35
    else
        tmux split-window -v -p 35
    fi

    local CAVA_PANE
    CAVA_PANE="$(tmux display-message -p '#{pane_id}')"
    tmux send-keys -t "$CAVA_PANE" "cava" C-m
    sleep 0.8

    if [ "$LANDSCAPE" = true ]; then tmux select-pane -L; else tmux select-pane -U; fi

    if [ "$RANDOM_MODE" = true ]; then
        if [ ! -s "$MUSIC_HISTORY" ]; then
            printf "${YELLOW}Music history masih kosong.${RESET}\n"
            tmux kill-pane -t "$CAVA_PANE" 2>/dev/null
            return 1
        fi

        local HISTORY_QUERY RESULTS MUSIC_URL MUSIC_TITLE
        HISTORY_QUERY="$(tail -n "$MUSIC_HISTORY_MAX" "$MUSIC_HISTORY" | tr '\n' ',' | sed 's/,$//')"
        printf "\n${CYAN}Finding something similar...${RESET}\n"
        RESULTS="$(yt-dlp --flat-playlist --print "%(webpage_url)s" --playlist-end 8 "ytsearch8:songs similar to $HISTORY_QUERY" 2>/dev/null)"

        MUSIC_URL="$(printf '%s\n' "$RESULTS" | grep -E '^https?://' | shuf -n 1)"
        if [ -z "$MUSIC_URL" ]; then
            printf "${RED}Gagal menemukan lagu.${RESET}\n"
            tmux kill-pane -t "$CAVA_PANE" 2>/dev/null
            return 1
        fi

        MUSIC_TITLE="$(yt-dlp --print "%(title)s" --skip-download "$MUSIC_URL" 2>/dev/null | head -n 1)"
        [ -z "$MUSIC_TITLE" ] && MUSIC_TITLE="Unknown"

        printf "\n${GREEN}✓ Recommended:${RESET} %s\n\n" "$MUSIC_TITLE"
        music_history_add "$MUSIC_TITLE"
        mpv --ao=pulse --audio-device='pulse/OpenSL_ES_sink' --no-video --ytdl-format="bestaudio/best" "$MUSIC_URL"
        tmux kill-pane -t "$CAVA_PANE" 2>/dev/null
        return
    fi

    while true; do
        local MUSIC_QUERY MUSIC_URL MUSIC_TITLE
        echo
        read -rp "YouTube URL / search (Enter untuk keluar): " MUSIC_QUERY
        [ -z "$MUSIC_QUERY" ] && break

        echo
        printf "${CYAN}Searching YouTube...${RESET}\n"
        if [[ "$MUSIC_QUERY" == http://* || "$MUSIC_QUERY" == https://* ]]; then
            MUSIC_URL="$MUSIC_QUERY"
        else
            MUSIC_URL="$(yt-dlp --flat-playlist --print "%(webpage_url)s" "ytsearch1:$MUSIC_QUERY" 2>/dev/null | head -n 1)"
        fi

        if [ -z "$MUSIC_URL" ]; then
            printf "${RED}Gagal menemukan lagu.${RESET}\n"
            continue
        fi

        MUSIC_TITLE="$(yt-dlp --print "%(title)s" --skip-download "$MUSIC_URL" 2>/dev/null | head -n 1)"
        [ -z "$MUSIC_TITLE" ] && MUSIC_TITLE="$MUSIC_QUERY"

        music_history_add "$MUSIC_TITLE"
        printf "\n${GREEN}Found:${RESET} %s\n\n" "$MUSIC_TITLE"
        mpv --ao=pulse --audio-device='pulse/OpenSL_ES_sink' --no-video --ytdl-format="bestaudio/best" "$MUSIC_URL"
        printf "\n${GREEN}✓ Lagu selesai.${RESET}\n"
    done

    tmux kill-pane -t "$CAVA_PANE" 2>/dev/null
    printf "\n${GREEN}✓ Music session stopped.${RESET}\n"
}

# Prompt & Auto Tmux
PS1='\[\033[36m\]\w\[\033[90m\] ❯ \[\033[0m\]'

if [[ $- == *i* ]] && [ -z "$TMUX" ] && [ -z "$MINIBASH_TMUX_STARTED" ]; then
    export MINIBASH_TMUX_STARTED=1
    tmux new-session -A -s main
fi
EOF

# 5. Langsung replace sesi terminal aktif dengan bash baru
exec bash
