#!/bin/bash
###############################################################################
#  OSCP EXAM COACH — The Husky Hacker
#  Timer, break reminders, progress check-ins, and motivational nudges
#  for the 23:45 OSCP exam window.
#
#  Usage: ./oscp-exam-coach.sh
###############################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ─── CONFIG ─────────────────────────────────────────────────────────────────
EXAM_DURATION_SEC=$((23 * 3600 + 45 * 60))  # 23h 45m
BREAK_INTERVAL_MIN=90                         # remind every 90 min
CHECKIN_INTERVAL_MIN=45                       # progress check every 45 min
SAVE_DIR="$HOME/.oscp-coach"
mkdir -p "$SAVE_DIR"

# ─── MOTIVATIONAL QUOTES ───────────────────────────────────────────────────
QUOTES=(
    "Saddle up boys. We're headed for the brick wall."
    "The box always tells you how to break it. Read the output."
    "Stuck? Go back to enumeration. The answer is there."
    "You didn't come this far to only come this far."
    "Trust your methodology. R.A.N.C.H. doesn't fail — impatience does."
    "Every OSCP holder was once exactly where you are right now."
    "Hydrate. A tired brain misses everything."
    "The privesc is always in the last place you look. So look everywhere."
    "Step away for 5 minutes. The exploit will still be there."
    "Default creds. Have you ACTUALLY tried them?"
    "Re-read the nmap. There's a port you glossed over."
    "You're The Husky Hacker. Act like it."
    "Slow is smooth, smooth is fast. Don't panic-spray."
    "If the exploit isn't working, your shell isn't the problem — your enum is."
    "The exam is a marathon, not a sprint. Pace yourself."
    "When in doubt, enumerate harder."
    "Sleep-deprived you is dumber than rested you. Take the break."
    "Document EVERYTHING as you go. Future you will thank present you."
    "Three boxes and you pass. Focus on the next one, not all of them."
    "Credential reuse. Try every password on every service. Every. Single. One."
)

# ─── SOUND / NOTIFICATION ──────────────────────────────────────────────────
alert() {
    # Terminal bell
    printf '\a'
    # Try notify-send if available (Linux desktop)
    if command -v notify-send &>/dev/null; then
        notify-send "OSCP Coach" "$1" 2>/dev/null
    fi
}

# ─── BANNER ─────────────────────────────────────────────────────────────────
banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << 'EOF'
   ____  _____ __________
  / __ \/ ___// ____/ __ \
 / / / /\__ \/ /   / /_/ /
/ /_/ /___/ / /___/ ____/
\____//____/\____/_/
   ___                  __
  / _ \___ ___ _______ / /_
 / ___/ _ `(_-<(_-< _ \ __/
/_/   \_,_/___/___/\___\__/

 Exam Coach — The Husky Hacker
EOF
    echo -e "${NC}"
}

# ─── TIME FORMATTING ───────────────────────────────────────────────────────
format_duration() {
    local secs=$1
    local h=$((secs / 3600))
    local m=$(( (secs % 3600) / 60 ))
    local s=$((secs % 60))
    printf "%02d:%02d:%02d" $h $m $s
}

format_clock() {
    date '+%I:%M %p'
}

# ─── PROGRESS TRACKING ─────────────────────────────────────────────────────
declare -A TARGETS
declare -a TARGET_ORDER=()
LOG_FILE=""

init_session() {
    local session_id
    session_id="exam_$(date '+%Y%m%d_%H%M%S')"
    LOG_FILE="$SAVE_DIR/${session_id}.log"
    echo "# OSCP Exam Coach Log — $(date)" > "$LOG_FILE"
    echo "# ==========================================" >> "$LOG_FILE"
}

log_event() {
    local elapsed
    elapsed=$(format_duration $(($(date +%s) - EXAM_START)))
    echo "[$elapsed] $(date '+%H:%M:%S') — $1" >> "$LOG_FILE"
}

random_quote() {
    echo "${QUOTES[$((RANDOM % ${#QUOTES[@]}))]}"
}

# ─── TARGET MANAGEMENT ─────────────────────────────────────────────────────
add_target() {
    echo ""
    echo -ne "  ${CYAN}Enter target IP or name: ${NC}"
    read -r target_name
    if [[ -z "$target_name" ]]; then
        return
    fi

    echo -e "  ${YELLOW}Target type:${NC}"
    echo -e "  ${CYAN}1${NC}) AD Set (40 pts)"
    echo -e "  ${CYAN}2${NC}) Standalone (20 pts)"
    echo -ne "  ${BOLD}Choose: ${NC}"
    read -r ttype

    local points=20
    local label="Standalone"
    if [[ "$ttype" == "1" ]]; then
        points=40
        label="AD Set"
    fi

    TARGETS["$target_name"]="type=$label|points=$points|user=no|root=no|started=$(date +%s)|notes="
    TARGET_ORDER+=("$target_name")
    log_event "TARGET ADDED: $target_name ($label, ${points}pts)"
    echo -e "\n  ${GREEN}Added ${BOLD}$target_name${NC}${GREEN} as $label (${points} pts)${NC}"
    sleep 1
}

update_target() {
    if [[ ${#TARGET_ORDER[@]} -eq 0 ]]; then
        echo -e "\n  ${RED}No targets added yet.${NC}"
        sleep 1
        return
    fi

    echo ""
    echo -e "  ${YELLOW}${BOLD}Select target to update:${NC}"
    local i=1
    for t in "${TARGET_ORDER[@]}"; do
        local data="${TARGETS[$t]}"
        local ttype user root
        ttype=$(echo "$data" | grep -oP 'type=\K[^|]+')
        user=$(echo "$data" | grep -oP 'user=\K[^|]+')
        root=$(echo "$data" | grep -oP 'root=\K[^|]+')

        local user_icon="[ ]"
        local root_icon="[ ]"
        [[ "$user" == "yes" ]] && user_icon="${GREEN}[✓]${NC}"
        [[ "$root" == "yes" ]] && root_icon="${GREEN}[✓]${NC}"

        echo -e "  ${CYAN}$i${NC}) $t ($ttype) — user: $user_icon  root: $root_icon"
        ((i++))
    done

    echo -ne "\n  ${BOLD}Choose target #: ${NC}"
    read -r choice

    if [[ -z "$choice" ]] || [[ $choice -lt 1 ]] || [[ $choice -gt ${#TARGET_ORDER[@]} ]]; then
        return
    fi

    local selected="${TARGET_ORDER[$((choice-1))]}"
    echo ""
    echo -e "  ${YELLOW}Updating ${BOLD}$selected${NC}"
    echo -e "  ${CYAN}1${NC}) Got user flag"
    echo -e "  ${CYAN}2${NC}) Got root flag"
    echo -e "  ${CYAN}3${NC}) Add a note"
    echo -e "  ${CYAN}4${NC}) Back"
    echo -ne "  ${BOLD}Choose: ${NC}"
    read -r action

    local data="${TARGETS[$selected]}"

    case "$action" in
        1)
            data=$(echo "$data" | sed 's/user=no/user=yes/')
            TARGETS["$selected"]="$data"
            log_event "USER FLAG: $selected"
            echo -e "\n  ${GREEN}${BOLD}User flag captured on $selected!${NC}"
            alert "User flag captured on $selected!"
            ;;
        2)
            data=$(echo "$data" | sed 's/root=no/root=yes/')
            TARGETS["$selected"]="$data"
            log_event "ROOT FLAG: $selected"
            echo -e "\n  ${GREEN}${BOLD}Root flag captured on $selected!${NC}"
            alert "Root flag captured on $selected!"
            ;;
        3)
            echo -ne "  ${CYAN}Note: ${NC}"
            read -r note
            log_event "NOTE ($selected): $note"
            echo -e "  ${GREEN}Note logged.${NC}"
            ;;
        *) return ;;
    esac
    sleep 1
}

# ─── SCORE CALCULATOR ──────────────────────────────────────────────────────
show_score() {
    echo ""
    echo -e "  ${MAGENTA}${BOLD}━━━ SCORE BOARD ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    local total=0

    for t in "${TARGET_ORDER[@]}"; do
        local data="${TARGETS[$t]}"
        local ttype user root points
        ttype=$(echo "$data" | grep -oP 'type=\K[^|]+')
        user=$(echo "$data" | grep -oP 'user=\K[^|]+')
        root=$(echo "$data" | grep -oP 'root=\K[^|]+')
        points=$(echo "$data" | grep -oP 'points=\K[^|]+')

        local earned=0
        local user_icon="${RED}✗${NC}"
        local root_icon="${RED}✗${NC}"

        if [[ "$ttype" == "AD Set" ]]; then
            # AD: all or nothing (40 pts for full chain)
            if [[ "$root" == "yes" ]]; then
                earned=40
                root_icon="${GREEN}✓${NC}"
                user_icon="${GREEN}✓${NC}"
            elif [[ "$user" == "yes" ]]; then
                earned=10
                user_icon="${GREEN}✓${NC}"
            fi
        else
            # Standalone: 10 user + 10 root
            if [[ "$user" == "yes" ]]; then
                earned=$((earned + 10))
                user_icon="${GREEN}✓${NC}"
            fi
            if [[ "$root" == "yes" ]]; then
                earned=$((earned + 10))
                root_icon="${GREEN}✓${NC}"
            fi
        fi

        total=$((total + earned))
        echo -e "  $user_icon $root_icon  ${BOLD}$t${NC} ($ttype) — ${CYAN}${earned}/${points} pts${NC}"
    done

    echo -e "  ${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    local color=$RED
    [[ $total -ge 50 ]] && color=$YELLOW
    [[ $total -ge 70 ]] && color=$GREEN

    echo -e "  ${BOLD}Total: ${color}${total} / 100 pts${NC}  (70 to pass)"

    if [[ $total -ge 70 ]]; then
        echo -e "  ${GREEN}${BOLD}PASSING SCORE!${NC}"
    else
        local needed=$((70 - total))
        echo -e "  ${YELLOW}Need ${needed} more points to pass${NC}"
    fi
    echo ""
}

# ─── BREAK TRACKER ─────────────────────────────────────────────────────────
LAST_BREAK=0
TOTAL_BREAKS=0
BREAK_TOTAL_SEC=0

take_break() {
    local break_start
    break_start=$(date +%s)
    LAST_BREAK=$break_start
    ((TOTAL_BREAKS++))

    log_event "BREAK STARTED (#$TOTAL_BREAKS)"

    echo ""
    echo -e "  ${GREEN}${BOLD}━━━ BREAK TIME ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${CYAN}$(random_quote)${NC}"
    echo ""
    echo -e "  ${YELLOW}Break checklist:${NC}"
    echo -e "  • Stand up and stretch"
    echo -e "  • Drink water"
    echo -e "  • Eat something if it's been 3+ hours"
    echo -e "  • Look away from screen (20-20-20 rule)"
    echo -e "  • Take a few deep breaths"
    echo -e "  • Bathroom break if needed"
    echo ""
    echo -e "  ${DIM}Timer running... Press Enter when you're back.${NC}"

    # Show live break timer
    while true; do
        local elapsed=$(($(date +%s) - break_start))
        echo -ne "\r  ${CYAN}Break duration: $(format_duration $elapsed)${NC}  "

        # Gentle nudge after 15 min
        if [[ $elapsed -eq $((15 * 60)) ]]; then
            echo ""
            echo -e "\n  ${YELLOW}15 minutes — solid break. Ready to get back to it?${NC}"
            alert "Break's been 15 minutes"
        fi

        # Stronger nudge after 30 min
        if [[ $elapsed -eq $((30 * 60)) ]]; then
            echo ""
            echo -e "\n  ${RED}30 minutes — clock is ticking, Husky. Time to saddle up.${NC}"
            alert "Break's been 30 minutes — time to get back!"
        fi

        read -t 1 -r input && break
    done

    local break_dur=$(($(date +%s) - break_start))
    BREAK_TOTAL_SEC=$((BREAK_TOTAL_SEC + break_dur))
    log_event "BREAK ENDED (#$TOTAL_BREAKS, duration: $(format_duration $break_dur))"

    echo ""
    echo -e "  ${GREEN}Break: $(format_duration $break_dur) — Back at it!${NC}"
    echo -e "  ${CYAN}$(random_quote)${NC}"
    echo ""
    sleep 2
}

# ─── PROGRESS CHECK-IN ─────────────────────────────────────────────────────
checkin() {
    local elapsed=$(($(date +%s) - EXAM_START))
    local remaining=$((EXAM_DURATION_SEC - elapsed))

    alert "Progress check-in time"

    echo ""
    echo -e "  ${YELLOW}${BOLD}━━━ CHECK-IN ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${BOLD}Time elapsed:${NC}   $(format_duration $elapsed)"
    echo -e "  ${BOLD}Time remaining:${NC} $(format_duration $remaining)"
    echo -e "  ${BOLD}Current time:${NC}   $(format_clock)"
    echo ""

    show_score

    echo -e "  ${CYAN}$(random_quote)${NC}"
    echo ""

    echo -e "  ${YELLOW}How are you feeling?${NC}"
    echo -e "  ${CYAN}1${NC}) Crushing it — making progress"
    echo -e "  ${CYAN}2${NC}) Stuck on current target"
    echo -e "  ${CYAN}3${NC}) Tired / need a break"
    echo -e "  ${CYAN}4${NC}) Frustrated"
    echo -ne "  ${BOLD}> ${NC}"
    read -r feeling

    case "$feeling" in
        1)
            echo -e "\n  ${GREEN}Let's go! Keep that momentum.${NC}"
            log_event "CHECK-IN: Feeling good, making progress"
            ;;
        2)
            echo ""
            echo -e "  ${YELLOW}${BOLD}When you're stuck — the R.A.N.C.H. reset:${NC}"
            echo -e "  1. Go back to nmap — missed port? Missed service version?"
            echo -e "  2. Re-enumerate web with a different wordlist"
            echo -e "  3. Try EVERY default cred combo on EVERY service"
            echo -e "  4. Credential reuse — spray found passwords everywhere"
            echo -e "  5. Google the EXACT version + 'exploit'"
            echo -e "  6. Read source code / config files line by line"
            echo -e "  7. Check internal services: ss -tlnp / netstat -ano"
            echo -e "  8. Consider: is this a rabbit hole? Move to another target."
            echo ""
            echo -e "  ${CYAN}Stuck for 30+ min on one vector? Move on. Come back fresh.${NC}"
            log_event "CHECK-IN: Stuck on current target"
            ;;
        3)
            echo -e "\n  ${GREEN}Take a break. Seriously. A 10-min break now saves 30 min of staring later.${NC}"
            log_event "CHECK-IN: Tired"
            echo -ne "  ${YELLOW}Start break now? (y/N): ${NC}"
            read -r yn
            [[ "$yn" =~ ^[yY]$ ]] && take_break
            ;;
        4)
            echo ""
            echo -e "  ${GREEN}${BOLD}Deep breath, Husky.${NC}"
            echo -e "  ${GREEN}Frustration means you care. Channel it.${NC}"
            echo ""
            echo -e "  ${YELLOW}Reset checklist:${NC}"
            echo -e "  • Close extra terminals — clean workspace"
            echo -e "  • Re-read your notes from scratch"
            echo -e "  • Pick ONE thing to try next — just one"
            echo -e "  • Set a 20-min timer on that one thing"
            echo -e "  • If it doesn't pan out, pivot — no ego"
            echo ""
            log_event "CHECK-IN: Frustrated"
            ;;
        *)
            log_event "CHECK-IN: No response"
            ;;
    esac
    echo ""
    echo -ne "  ${DIM}Press Enter to continue...${NC}"
    read -r
}

# ─── EXAM TIMELINE ADVISOR ─────────────────────────────────────────────────
timeline_advice() {
    local elapsed=$(($(date +%s) - EXAM_START))
    local hours=$((elapsed / 3600))

    echo ""
    echo -e "  ${MAGENTA}${BOLD}━━━ TIMELINE ADVISOR ━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Calculate current score
    local total=0
    for t in "${TARGET_ORDER[@]}"; do
        local data="${TARGETS[$t]}"
        local ttype user root
        ttype=$(echo "$data" | grep -oP 'type=\K[^|]+')
        user=$(echo "$data" | grep -oP 'user=\K[^|]+')
        root=$(echo "$data" | grep -oP 'root=\K[^|]+')

        if [[ "$ttype" == "AD Set" ]]; then
            [[ "$root" == "yes" ]] && total=$((total + 40))
            [[ "$root" != "yes" && "$user" == "yes" ]] && total=$((total + 10))
        else
            [[ "$user" == "yes" ]] && total=$((total + 10))
            [[ "$root" == "yes" ]] && total=$((total + 10))
        fi
    done

    if [[ $hours -lt 4 ]]; then
        echo -e "  ${CYAN}Hour $hours — Early Game${NC}"
        echo -e "  You should be deep in the AD set right now."
        echo -e "  Target: Foothold on AD within first 3–4 hours."
        if [[ $total -ge 10 ]]; then
            echo -e "  ${GREEN}You've got points on the board — solid start.${NC}"
        else
            echo -e "  ${YELLOW}No points yet — that's okay. Keep enumerating.${NC}"
        fi
    elif [[ $hours -lt 8 ]]; then
        echo -e "  ${CYAN}Hour $hours — Mid Game (AD Focus)${NC}"
        echo -e "  AD set should be wrapping up or done."
        if [[ $total -ge 40 ]]; then
            echo -e "  ${GREEN}AD set complete! Move to standalones.${NC}"
        elif [[ $total -ge 10 ]]; then
            echo -e "  ${YELLOW}Got a foothold — push for the full chain.${NC}"
            echo -e "  ${YELLOW}If truly stuck after hour 8, pivot to standalones.${NC}"
        else
            echo -e "  ${RED}No AD progress — consider pivoting to standalones soon.${NC}"
            echo -e "  ${RED}You need 70 pts. Three full standalones = 60. Not enough alone.${NC}"
        fi
    elif [[ $hours -lt 16 ]]; then
        echo -e "  ${CYAN}Hour $hours — Standalone Phase${NC}"
        echo -e "  3–4 hours per standalone. Stick to methodology."
        local needed=$((70 - total))
        if [[ $total -ge 70 ]]; then
            echo -e "  ${GREEN}${BOLD}You're passing! Keep going for bonus points and confidence.${NC}"
        elif [[ $needed -le 20 ]]; then
            echo -e "  ${YELLOW}Need just $needed more pts — one more box gets you there.${NC}"
        else
            echo -e "  ${YELLOW}Need $needed more pts. Stay calm, stay methodical.${NC}"
        fi
    elif [[ $hours -lt 20 ]]; then
        echo -e "  ${CYAN}Hour $hours — Late Game${NC}"
        if [[ $total -ge 70 ]]; then
            echo -e "  ${GREEN}${BOLD}PASSING! Start documenting your report notes if you haven't.${NC}"
        else
            local needed=$((70 - total))
            echo -e "  ${YELLOW}Need $needed more pts. Focus on low-hanging fruit.${NC}"
            echo -e "  ${YELLOW}Any user-only flags you can grab? Every 10 pts matters.${NC}"
        fi
    else
        echo -e "  ${RED}${BOLD}Hour $hours — Final Stretch${NC}"
        if [[ $total -ge 70 ]]; then
            echo -e "  ${GREEN}You're passing! Make sure screenshots and notes are solid.${NC}"
        else
            local needed=$((70 - total))
            echo -e "  ${RED}Need $needed pts. Hail mary time:${NC}"
            echo -e "  • Any half-finished exploits?"
            echo -e "  • Any user flags within reach?"
            echo -e "  • Credential reuse on remaining targets?"
        fi
    fi
    echo ""
    echo -ne "  ${DIM}Press Enter to continue...${NC}"
    read -r
}

# ─── VIEW LOG ───────────────────────────────────────────────────────────────
view_log() {
    echo ""
    echo -e "  ${MAGENTA}${BOLD}━━━ SESSION LOG ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    if [[ -f "$LOG_FILE" ]]; then
        while IFS= read -r line; do
            echo -e "  ${DIM}$line${NC}"
        done < "$LOG_FILE"
    else
        echo -e "  ${DIM}No log entries yet.${NC}"
    fi
    echo ""
    echo -ne "  ${DIM}Press Enter to continue...${NC}"
    read -r
}

# ─── BACKGROUND TIMER ──────────────────────────────────────────────────────
LAST_CHECKIN=0
BG_PID=""

background_timer() {
    while true; do
        sleep 60
        local now
        now=$(date +%s)
        local elapsed=$((now - EXAM_START))

        # Break reminder
        local since_break=$((now - LAST_BREAK))
        if [[ $LAST_BREAK -gt 0 ]] && [[ $((since_break / 60)) -ge $BREAK_INTERVAL_MIN ]]; then
            alert "You've been going for ${BREAK_INTERVAL_MIN} minutes — consider a break"
            LAST_BREAK=$now  # reset so it doesn't spam
        fi

        # Time milestones
        local hours=$((elapsed / 3600))
        local mins=$(( (elapsed % 3600) / 60 ))

        # Alert at key milestones
        case "${hours}:${mins}" in
            "4:0")  alert "4 hours in — AD set check: do you have a foothold?" ;;
            "8:0")  alert "8 hours — one third done. Time to assess standalones." ;;
            "12:0") alert "Halfway point! Check your score." ;;
            "16:0") alert "16 hours — 7:45 remaining. How's the score?" ;;
            "20:0") alert "20 hours — 3:45 left. Final push." ;;
            "22:0") alert "22 hours — under 2 hours. Wrap up and document." ;;
            "23:0") alert "FINAL 45 MINUTES — screenshot everything!" ;;
        esac

        # Remaining time warnings
        local remaining=$((EXAM_DURATION_SEC - elapsed))
        if [[ $remaining -le 0 ]]; then
            alert "EXAM TIME IS UP!"
            echo -e "\n\n  ${RED}${BOLD}═══ TIME'S UP! ═══${NC}\n"
            break
        fi
    done
}

# ─── MAIN MENU ──────────────────────────────────────────────────────────────
EXAM_START=0

main_menu() {
    local now
    now=$(date +%s)
    local elapsed=$((now - EXAM_START))
    local remaining=$((EXAM_DURATION_SEC - elapsed))

    banner

    # Status bar
    local elapsed_fmt remaining_fmt
    elapsed_fmt=$(format_duration $elapsed)
    remaining_fmt=$(format_duration $remaining)

    local bar_color=$GREEN
    [[ $remaining -lt $((4 * 3600)) ]] && bar_color=$YELLOW
    [[ $remaining -lt $((2 * 3600)) ]] && bar_color=$RED

    echo -e "  ${BOLD}Elapsed:${NC} $elapsed_fmt    ${bar_color}${BOLD}Remaining:${NC} $remaining_fmt    ${DIM}$(format_clock)${NC}"
    echo -e "  ${DIM}Breaks: $TOTAL_BREAKS ($(format_duration $BREAK_TOTAL_SEC) total)${NC}"
    echo ""

    # Quick score
    if [[ ${#TARGET_ORDER[@]} -gt 0 ]]; then
        local total=0
        for t in "${TARGET_ORDER[@]}"; do
            local data="${TARGETS[$t]}"
            local ttype user root
            ttype=$(echo "$data" | grep -oP 'type=\K[^|]+')
            user=$(echo "$data" | grep -oP 'user=\K[^|]+')
            root=$(echo "$data" | grep -oP 'root=\K[^|]+')
            if [[ "$ttype" == "AD Set" ]]; then
                [[ "$root" == "yes" ]] && total=$((total + 40))
                [[ "$root" != "yes" && "$user" == "yes" ]] && total=$((total + 10))
            else
                [[ "$user" == "yes" ]] && total=$((total + 10))
                [[ "$root" == "yes" ]] && total=$((total + 10))
            fi
        done
        local score_color=$RED
        [[ $total -ge 50 ]] && score_color=$YELLOW
        [[ $total -ge 70 ]] && score_color=$GREEN
        echo -e "  ${BOLD}Score: ${score_color}${total}/100${NC} pts  (70 to pass)"
    fi
    echo ""

    echo -e "  ${BOLD}What do you need?${NC}"
    echo ""
    echo -e "  ${CYAN}1${NC})  Add target"
    echo -e "  ${CYAN}2${NC})  Update target (flag captured)"
    echo -e "  ${CYAN}3${NC})  Score board"
    echo -e "  ${CYAN}4${NC})  Take a break"
    echo -e "  ${CYAN}5${NC})  Progress check-in"
    echo -e "  ${CYAN}6${NC})  Timeline advisor"
    echo -e "  ${CYAN}7${NC})  Motivational quote"
    echo -e "  ${CYAN}8${NC})  View session log"
    echo -e "  ${CYAN}9${NC})  Change break interval (current: ${BREAK_INTERVAL_MIN} min)"
    echo -e "  ${CYAN}q${NC})  End session"
    echo ""
}

start_exam() {
    banner
    echo ""
    echo -e "  ${YELLOW}${BOLD}Welcome to OSCP Exam Coach${NC}"
    echo -e "  ${DIM}Your timer, break reminder, and hype man for the next 23:45.${NC}"
    echo ""
    echo -e "  ${CYAN}$(random_quote)${NC}"
    echo ""
    echo -e "  ${YELLOW}When did your exam start?${NC}"
    echo -e "  ${CYAN}1${NC}) Right now"
    echo -e "  ${CYAN}2${NC}) Enter a start time (e.g., if exam already started)"
    echo -ne "  ${BOLD}Choose: ${NC}"
    read -r start_choice

    case "$start_choice" in
        2)
            echo -ne "  ${CYAN}How many minutes ago did it start? ${NC}"
            read -r mins_ago
            if [[ "$mins_ago" =~ ^[0-9]+$ ]]; then
                EXAM_START=$(( $(date +%s) - (mins_ago * 60) ))
            else
                EXAM_START=$(date +%s)
            fi
            ;;
        *)
            EXAM_START=$(date +%s)
            ;;
    esac

    LAST_BREAK=$EXAM_START
    LAST_CHECKIN=$EXAM_START

    init_session
    log_event "EXAM SESSION STARTED"

    echo ""
    echo -e "  ${GREEN}${BOLD}Timer started! Let's get this bread, Husky. 🐺${NC}"
    echo ""
    sleep 2

    # Start background timer
    background_timer &
    BG_PID=$!

    # Main loop
    while true; do
        main_menu
        echo -ne "  ${BOLD}> ${NC}"
        read -r choice

        case "$choice" in
            1) add_target ;;
            2) update_target ;;
            3) show_score; echo -ne "  ${DIM}Press Enter...${NC}"; read -r ;;
            4) take_break ;;
            5) checkin ;;
            6) timeline_advice ;;
            7)
                echo ""
                echo -e "  ${CYAN}${BOLD}$(random_quote)${NC}"
                echo ""
                sleep 2
                ;;
            8) view_log ;;
            9)
                echo -ne "  ${CYAN}New break interval (minutes): ${NC}"
                read -r new_int
                if [[ "$new_int" =~ ^[0-9]+$ ]] && [[ $new_int -gt 0 ]]; then
                    BREAK_INTERVAL_MIN=$new_int
                    echo -e "  ${GREEN}Break reminder set to every ${new_int} minutes.${NC}"
                    log_event "BREAK INTERVAL CHANGED: ${new_int} min"
                fi
                sleep 1
                ;;
            q|Q)
                echo ""
                local elapsed=$(($(date +%s) - EXAM_START))
                show_score
                echo -e "  ${BOLD}Session duration:${NC} $(format_duration $elapsed)"
                echo -e "  ${BOLD}Breaks taken:${NC} $TOTAL_BREAKS ($(format_duration $BREAK_TOTAL_SEC))"
                echo -e "  ${BOLD}Log saved to:${NC} $LOG_FILE"
                echo ""
                echo -e "  ${GREEN}${BOLD}You did the work, Husky. Trust it. 🐺${NC}"
                echo ""
                log_event "SESSION ENDED"
                # Kill background timer
                [[ -n "$BG_PID" ]] && kill "$BG_PID" 2>/dev/null
                exit 0
                ;;
            *) ;;
        esac
    done
}

# ─── ENTRY POINT ────────────────────────────────────────────────────────────

# Handle Ctrl+C gracefully
cleanup() {
    echo ""
    echo -e "  ${YELLOW}Saving session...${NC}"
    [[ -n "$BG_PID" ]] && kill "$BG_PID" 2>/dev/null
    log_event "SESSION INTERRUPTED (Ctrl+C)"
    echo -e "  ${BOLD}Log saved to:${NC} $LOG_FILE"
    echo -e "  ${GREEN}Stay sharp, Husky. 🐺${NC}"
    echo ""
    exit 0
}
trap cleanup SIGINT SIGTERM

start_exam
