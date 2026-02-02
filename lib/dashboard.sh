#!/bin/bash
# shellcheck disable=SC2059

PLEX_URL="http://localhost:32400"
PLEX_TOKEN="${PLEX_TOKEN:-$(defaults read com.plexapp.plexmediaserver PlexOnlineToken 2>/dev/null)}"
QBIT_URL="http://192.168.1.133:8080"
QBIT_USER="${QBIT_USER:-admin}"
QBIT_PASS="${QBIT_PASS:-}"
QBIT_COOKIE="/tmp/qbt_cookie.txt"
REFRESH_INTERVAL=60
ANIM_SPEED=1
CAT_MAX=14

SERVICES=("Plex Media Server" "Sonarr" "Radarr" "Prowlarr" "AdGuardHome" "syncthing")
SERVICE_NAMES=("Plex" "Sonarr" "Radarr" "Prowlarr" "AdGuard" "Syncthing")

GREEN='\033[1;32m'
RED='\033[1;31m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[1;35m'
WHITE='\033[1;37m'
DIM='\033[0;37m'
NC='\033[0m'
CL='\033[K'
RC='\033[34G'

cleanup() {
    rm -f "$QBIT_COOKIE"
    tput reset
}
trap cleanup EXIT INT TERM

check_services() {
    local down=""
    for i in "${!SERVICES[@]}"; do
        pgrep -q "${SERVICES[$i]}" || down="${down}${SERVICE_NAMES[$i]} "
    done
    if [ -z "$down" ]; then
        printf "${YELLOW}║${NC} Services:  ${GREEN}ALL OK${NC}${CL}${RC}${YELLOW}║${NC}\n"
    else
        printf "${YELLOW}║${NC} Services:  ${RED}DOWN: ${down}${NC}${CL}${RC}${YELLOW}║${NC}\n"
    fi
}

check_disk() {
    if mount | grep -q Saved_Media; then
        local disk_info
        disk_info=$(df -h /Volumes/Saved_Media | awk 'NR==2{gsub(/%/,"%%",$5); print $5}')
        printf "${YELLOW}║${NC} Storage:   ${GREEN}${disk_info}${NC}${CL}${RC}${YELLOW}║${NC}\n"
    else
        printf "${YELLOW}║${NC} Storage:   ${DIM}NOT CONNECTED${NC}${CL}${RC}${YELLOW}║${NC}\n"
    fi
}

check_streams() {
    local stream_count
    stream_count=$(curl -s "${PLEX_URL}/status/sessions?X-Plex-Token=${PLEX_TOKEN}" -H "Accept: application/json" 2>/dev/null | python3 -c '
import json,sys
try:
    d=json.load(sys.stdin)
    print(d["MediaContainer"]["size"])
except: print("0")' 2>/dev/null)
    if [ "$stream_count" = "0" ]; then
        printf "${YELLOW}║${NC} Streaming: ${DIM}0${NC}${CL}${RC}${YELLOW}║${NC}\n"
    else
        printf "${YELLOW}║${NC} Streaming: ${MAGENTA}${stream_count}${NC}${CL}${RC}${YELLOW}║${NC}\n"
    fi
}

check_downloads() {
    curl -s --max-time 3 "${QBIT_URL}/api/v2/auth/login" -d "username=${QBIT_USER}&password=${QBIT_PASS}" -c "$QBIT_COOKIE" >/dev/null 2>&1
    local qbt
    qbt=$(curl -s --max-time 3 "${QBIT_URL}/api/v2/transfer/info" -b "$QBIT_COOKIE" 2>/dev/null | python3 -c '
import json,sys
try:
    d=json.load(sys.stdin)
    dl=d.get("dl_info_speed",0)
    if dl > 0:
        mb=dl/1024/1024
        print("DL: "+str(round(mb,1))+" MB/s")
    else:
        print("Idle")
except: print("---")' 2>/dev/null)
    if [ "$qbt" = "Idle" ] || [ "$qbt" = "---" ]; then
        printf "${YELLOW}║${NC} Downloads: ${DIM}${qbt}${NC}${CL}${RC}${YELLOW}║${NC}\n"
    else
        printf "${YELLOW}║${NC} Downloads: ${GREEN}${qbt}${NC}${CL}${RC}${YELLOW}║${NC}\n"
    fi
}

draw_header() {
    printf "${YELLOW}╔════════════════════════════════╗${NC}${CL}\n"
    printf "${YELLOW}║${NC}      ${YELLOW}★${NC} ${WHITE}MEDIA SERVER${NC} ${YELLOW}★${NC}${CL}${RC}${YELLOW}║${NC}\n"
    printf "${YELLOW}╠════════════════════════════════╣${NC}${CL}\n"
}

draw_links() {
    printf "${YELLOW}┌──────────┬─────────────────────┐${NC}${CL}\n"
    printf "${YELLOW}│${NC} Plex     ${YELLOW}│${NC} ${CYAN}http://plex.lan${NC}     ${YELLOW}│${NC}${CL}\n"
    printf "${YELLOW}│${NC} Radarr   ${YELLOW}│${NC} ${CYAN}http://radarr.lan${NC}   ${YELLOW}│${NC}${CL}\n"
    printf "${YELLOW}│${NC} Sonarr   ${YELLOW}│${NC} ${CYAN}http://sonarr.lan${NC}   ${YELLOW}│${NC}${CL}\n"
    printf "${YELLOW}│${NC} Prowlarr ${YELLOW}│${NC} ${CYAN}http://prowlarr.lan${NC} ${YELLOW}│${NC}${CL}\n"
    printf "${YELLOW}│${NC} AdGuard  ${YELLOW}│${NC} ${CYAN}http://adguard.lan${NC}  ${YELLOW}│${NC}${CL}\n"
    printf "${YELLOW}│${NC} Sync     ${YELLOW}│${NC} ${CYAN}http://sync.lan${NC}     ${YELLOW}│${NC}${CL}\n"
    printf "${YELLOW}│${NC} qBit     ${YELLOW}│${NC} ${CYAN}http://qbit.lan${NC}     ${YELLOW}│${NC}${CL}\n"
    printf "${YELLOW}└──────────┴─────────────────────┘${NC}${CL}\n"
}

animate_cat() {
    local last_line=$(($(tput lines) - 1))
    for _ in $(seq 1 "$REFRESH_INTERVAL"); do
        tput cup "$last_line" 0
        printf "${CL}"
        tput cup "$last_line" "$CAT_POS"
        if [ "$CAT_DIR" -eq 1 ]; then
            printf "${DIM}~(=^..^)${NC}"
        else
            printf "${DIM}(^..^=)~${NC}"
        fi
        CAT_POS=$((CAT_POS + CAT_DIR))
        if [ "$CAT_POS" -ge "$CAT_MAX" ]; then
            CAT_DIR=-1
        elif [ "$CAT_POS" -le 0 ]; then
            CAT_DIR=1
        fi
        sleep "$ANIM_SPEED"
    done
}

CAT_POS=0
CAT_DIR=1

clear
while true; do
    tput cup 0 0
    draw_header
    check_services
    check_disk
    check_streams
    check_downloads
    printf "${YELLOW}╠════════════════════════════════╣${NC}${CL}\n"
    printf "${YELLOW}║${NC} ${DIM}Up: $(uptime | sed 's/.*up //' | sed 's/,.*//')${NC}${CL}${RC}${YELLOW}║${NC}\n"
    printf "${YELLOW}╚════════════════════════════════╝${NC}${CL}\n"
    printf "${CL}\n"
    draw_links
    tput ed
    animate_cat
done
