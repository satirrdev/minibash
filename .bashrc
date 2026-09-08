alias log="proot-distro login debian"
export PATH="$HOME/.local/bin:$PATH"

# ==========================================================
#                    SATIR TERMUX BASHRC
# ==========================================================

# ----------------------------------------------------------
# PATH
# ----------------------------------------------------------

export PATH="$HOME/.local/bin:$PATH"


# ==========================================================
#                    COLORS
# ==========================================================

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


# ==========================================================
#                    SATIRFETCH SESSION
# ==========================================================

SATIRFETCH_DIR="$HOME/.local/share/satirfetch"
mkdir -p "$SATIRFETCH_DIR"

SATIRFETCH_SESSION="$SATIRFETCH_DIR/session.start"
SATIRFETCH_LAST="$SATIRFETCH_DIR/session.last"
SATIRFETCH_ACTIVITY="$SATIRFETCH_DIR/activity.log"

touch "$SATIRFETCH_ACTIVITY"

# Hanya buat satu session tracker per shell utama
if [[ $- == *i* ]] && [ -z "$SATIRFETCH_SESSION_ACTIVE" ]; then

    export SATIRFETCH_SESSION_ACTIVE=1

    date '+%s' > "$SATIRFETCH_SESSION"
    date '+%s' > "$SATIRFETCH_LAST"

    satirfetch_session_update() {
        local now
        local last
        local delta
        local today
        local current
        local file

        now="$(date '+%s')"
        last="$(cat "$SATIRFETCH_LAST" 2>/dev/null)"

        if [[ "$last" =~ ^[0-9]+$ ]]; then
            delta=$((now - last))

            # Maksimal 4 jam per update
            if [ "$delta" -gt 0 ] && [ "$delta" -lt 14400 ]; then
                today="$(date '+%Y-%m-%d')"
                file="$SATIRFETCH_ACTIVITY"

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

        printf '%s\n' "$now" > "$SATIRFETCH_LAST"
    }

    trap 'satirfetch_session_update' EXIT
fi



# ==========================================================
#                    BOOT SEQUENCE
# ==========================================================

if [[ $- == *i* ]] && [ -z "$SATIRFETCH_BOOTED" ]; then

    export SATIRFETCH_BOOTED=1

    clear

    printf "\n"
    printf "${CYAN}${BOLD}Booting SatirOS...${RESET}\n\n"

    boot_ok() {
        printf "${WHITE}Starting %-30s${RESET} [${GREEN} OK ${RESET}]\n" "$1"
        sleep 0.10
    }

    boot_ok "Termux environment"
    boot_ok "Filesystem"
    boot_ok "Device manager"
    boot_ok "Network manager"
    boot_ok "Audio server"
    boot_ok "Terminal services"
    boot_ok "Shell environment"
    boot_ok "Session tracker"

    printf "\n"
    printf "${GREEN}${BOLD}System initialization complete.${RESET}\n"

    sleep 0.25

    if command -v satirfetch >/dev/null 2>&1; then
        satirfetch
    fi
fi

bash .local/share/satirfetch/start.sh

# ==========================================================
#                    RANDOM MOTD
# ==========================================================

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
    "Environment loaded successfully."
    "System ready for commands."
    "Keep building."
    "Less noise. More code."
    "Read the error message."
    "Automation beats repetition."
    "Knowledge compounds."
    "Stay curious."
    "Keep experimenting."
    "Build something useful."
)

RANDOM_MOTD="${MOTDS[$RANDOM % ${#MOTDS[@]}]}"

printf "\n"
printf "${GRAY}%s${RESET}\n\n" "$RANDOM_MOTD"


# ==========================================================
#                    BASIC ALIASES
# ==========================================================

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


# ==========================================================
#                    HELP
# ==========================================================

helpme() {
    printf "\n"
    printf "${CYAN}${BOLD}Termux Commands${RESET}\n"
    printf "${GRAY}────────────────────────────────────${RESET}\n"
    printf "${GREEN}ll${RESET}              Detailed file list\n"
    printf "${GREEN}la${RESET}              Show hidden files\n"
    printf "${GREEN}l${RESET}               Compact file list\n"
    printf "${GREEN}c${RESET}               Clear terminal\n"
    printf "${GREEN}update${RESET}          Update Termux\n"
    printf "${GREEN}reload${RESET}          Reload .bashrc\n"
    printf "${GREEN}debian${RESET}          Enter Debian\n"
    printf "${GREEN}satirfetch${RESET}     System information\n"
    printf "${GREEN}music${RESET}           Music player\n"
    printf "${GREEN}music --landscape${RESET}  Music + CAVA landscape\n"
    printf "${GREEN}music -r${RESET}       Discover from music history\n"
    printf "${GREEN}music -h${RESET}       Show music history\n"
    printf "${GREEN}music -c${RESET}       Clear music history\n"
    printf "${GREEN}poweroff${RESET}       Shut down Termux\n"
    printf "\n"
}


# ==========================================================
#                    POWEROFF
# ==========================================================

poweroff() {
    printf "\n"
    printf "${YELLOW}${BOLD}Shutting down Satir Termux...${RESET}\n\n"

    printf "${WHITE}Stopping music player${RESET} [${GREEN} OK ${RESET}]\n"
    pkill -TERM mpv 2>/dev/null

    printf "${WHITE}Stopping visualizer${RESET} [${GREEN} OK ${RESET}]\n"
    pkill -TERM cava 2>/dev/null

    printf "${WHITE}Stopping audio server${RESET} [${GREEN} OK ${RESET}]\n"
    pulseaudio --kill 2>/dev/null

    printf "${WHITE}Stopping tmux${RESET} [${GREEN} OK ${RESET}]\n"
    tmux kill-server 2>/dev/null

    sleep 0.4

    printf "\n"
    printf "${GREEN}${BOLD}System halted.${RESET}\n"

    sleep 0.4

    am force-stop com.termux 2>/dev/null
    exit
}


# ==========================================================
#                    MUSIC PLAYER
# ==========================================================

music() {
    local LANDSCAPE=false
    local RANDOM_MODE=false
    local HISTORY_MODE=false
    local CLEAR_MODE=false

    local MUSIC_DIR="$HOME/.local/share/satirfetch"
    local MUSIC_HISTORY="$MUSIC_DIR/music_history"
    local MUSIC_HISTORY_MAX=10

    mkdir -p "$MUSIC_DIR"
    touch "$MUSIC_HISTORY"

    # Argument Parser
    while [ $# -gt 0 ]; do
        case "$1" in
            --landscape) LANDSCAPE=true; shift ;;
            -r|--random) RANDOM_MODE=true; shift ;;
            -h|--history) HISTORY_MODE=true; shift ;;
            -c|--clear) CLEAR_MODE=true; shift ;;
            *) break ;;
        esac
    done

    # Helper Functions
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

        printf "\n"
        printf "${CYAN}${BOLD}╭──────────────────────────────╮${RESET}\n"
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

    # Modes Check
    if [ "$CLEAR_MODE" = true ]; then
        music_history_clear
        return
    fi

    if [ "$HISTORY_MODE" = true ]; then
        music_history_show
        return
    fi

    # Dependency Check
    for cmd in yt-dlp mpv cava tmux; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            printf "${RED}%s belum terinstall.${RESET}\n" "$cmd"
            return 1
        fi
    done

    # Cek Sesi Tmux
    if [ -z "$TMUX" ]; then
        printf "${RED}Fungsi music butuh tmux. Jalankan di dalam sesi tmux!${RESET}\n"
        return 1
    fi

    printf "\n"
    printf "${CYAN}${BOLD}╭──────────────────────────────╮${RESET}\n"
    printf "${CYAN}${BOLD}│        MUSIC PLAYER          │${RESET}\n"
    printf "${CYAN}${BOLD}╰──────────────────────────────╯${RESET}\n"

    # Split CAVA Pane
    if [ "$LANDSCAPE" = true ]; then
        tmux split-window -h -p 35
    else
        tmux split-window -v -p 35
    fi

    local CAVA_PANE
    CAVA_PANE="$(tmux display-message -p '#{pane_id}')"
    tmux send-keys -t "$CAVA_PANE" "cava" C-m
    sleep 1

    if [ "$LANDSCAPE" = true ]; then
        tmux select-pane -L
    else
        tmux select-pane -U
    fi

    # Random / Discover Mode
    if [ "$RANDOM_MODE" = true ]; then
        if [ ! -s "$MUSIC_HISTORY" ]; then
            printf "${YELLOW}Music history masih kosong.${RESET}\n"
            printf "${GRAY}Cari beberapa lagu terlebih dahulu.${RESET}\n"
            tmux kill-pane -t "$CAVA_PANE" 2>/dev/null
            return 1
        fi

        printf "\n"
        printf "${MAGENTA}${BOLD}󰒭 MUSIC DISCOVER${RESET}\n"
        printf "${GRAY}──────────────────────────────${RESET}\n\n"
        printf "${GRAY}Based on:${RESET}\n"

        while IFS= read -r SONG; do
            printf "  ${GRAY}•${RESET} %s\n" "$SONG"
        done < "$MUSIC_HISTORY"

        local HISTORY_QUERY
        HISTORY_QUERY="$(tail -n "$MUSIC_HISTORY_MAX" "$MUSIC_HISTORY" | tr '\n' ',' | sed 's/,$//')"

        printf "\n${CYAN}Finding something similar...${RESET}\n"

        local SEARCH_QUERY="songs similar to $HISTORY_QUERY"
        local RESULTS
        RESULTS="$(yt-dlp --flat-playlist --print "%(webpage_url)s" --playlist-end 8 "ytsearch8:$SEARCH_QUERY" 2>/dev/null)"

        if [ -z "$RESULTS" ]; then
            printf "${RED}Gagal menemukan rekomendasi.${RESET}\n"
            tmux kill-pane -t "$CAVA_PANE" 2>/dev/null
            return 1
        fi

        local MUSIC_URL
        MUSIC_URL="$(printf '%s\n' "$RESULTS" | grep -E '^https?://' | shuf -n 1)"

        if [ -z "$MUSIC_URL" ]; then
            printf "${RED}Tidak mendapatkan hasil YouTube.${RESET}\n"
            tmux kill-pane -t "$CAVA_PANE" 2>/dev/null
            return 1
        fi

        local MUSIC_TITLE
        MUSIC_TITLE="$(yt-dlp --print "%(title)s" --skip-download "$MUSIC_URL" 2>/dev/null | head -n 1)"
        [ -z "$MUSIC_TITLE" ] && MUSIC_TITLE="Unknown"

        printf "\n${GREEN}✓ Recommended:${RESET} %s\n\n" "$MUSIC_TITLE"
        music_history_add "$MUSIC_TITLE"

        mpv --ao=pulse --audio-device='pulse/OpenSL_ES_sink' --no-video --ytdl-format="bestaudio/best" "$MUSIC_URL"

        printf "\n${GREEN}✓ Music session stopped.${RESET}\n"
        tmux kill-pane -t "$CAVA_PANE" 2>/dev/null
        return
    fi

    # Normal Search Loop
    while true; do
        local MUSIC_QUERY
        local MUSIC_URL
        local MUSIC_TITLE

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
        printf "${GRAY}Standby. Cari lagu berikutnya.${RESET}\n"
    done

    tmux kill-pane -t "$CAVA_PANE" 2>/dev/null
    printf "\n${GREEN}✓ Music session stopped.${RESET}\n"
}


# ==========================================================
#                    SIMPLE PROMPT
# ==========================================================

PS1='\[\033[36m\]\w\[\033[90m\] ❯ \[\033[0m\]'


# ==========================================================
#                    AUTO TMUX
# ==========================================================

if [[ $- == *i* ]] && [ -z "$TMUX" ] && [ -z "$SATIRFETCH_TMUX_STARTED" ]; then
    export SATIRFETCH_TMUX_STARTED=1
    tmux new-session -A -s main
fi