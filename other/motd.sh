#!/data/data/com.termux/files/usr/bin/bash
# Color codes
NC=$'\e[0;39m'
G=$'\e[1;32m'
C=$'\e[1;36m'
R=$'\e[1;31m'
BOLD=$'\033[1m'
WHITE=$'\e[0;37m'
DIM=$'\e[2m'
UNDIM=$'\e[22m'

if cmd package list packages --user 0 -e -f | sed 's/package://; s/\.apk=/\.apk /' | grep -q "com.termux.api"; then
    is_termux_api_installed=true
    if ! command -v termux-api-start &>/dev/null; then
        echo "PLEASE RUN: pkg install termux-api"
    fi
else
    is_termux_api_installed=false
fi

if [[ "$is_termux_api_installed" == "true" ]]; then
    #battry level
    BATTERY=$(termux-battery-status | jq '.percentage')
    BATTERY_STATUS=$(termux-battery-status | jq -r '.status')
fi
# Android distro info
if [[ -d /system/app/ && -d /system/priv-app ]]; then
    DISTRO="Android $(getprop ro.build.version.release)"
    MODEL="$(getprop ro.product.brand) $(getprop ro.product.model)"
fi

# Normalize Termux build string
termux_build="${TERMUX_APK_RELEASE,,}"
termux_build="${termux_build^}"

# Read thermal zone temperature (first readable)
raw_temp=""
for zone in /sys/class/thermal/thermal_zone*/temp; do
    if [[ -r "$zone" ]]; then
        raw_temp=$(<"$zone")
        break
    fi
done
if [[ $raw_temp =~ ^[0-9]+$ ]]; then
    TEMP=$((raw_temp > 1000 ? raw_temp / 1000 : raw_temp / 100))
elif command -v termux-battery-status >/dev/null 2>&1; then
    TEMP=$(termux-battery-status | jq -r .temperature | cut -d'.' -f1)
else
    TEMP="N/A"
fi

# SoC detection
PROC_BRAND=$(getprop ro.soc.manufacturer | tr '[:lower:]' '[:upper:]')
PROC_MODEL=$(getprop ro.soc.model | tr '[:lower:]' '[:upper:]')
HARDWARE=$(getprop ro.hardware | tr '[:lower:]' '[:upper:]')
if [[ -n $PROC_BRAND && -n $PROC_MODEL ]]; then
    soc_details="$PROC_BRAND $PROC_MODEL"
else
    soc_details="$HARDWARE"
fi

# vCPU count
PROCESSOR_COUNT=$(grep -c '^processor' /proc/cpuinfo)

# Temperature icon
if [[ $TEMP =~ ^[0-9]+$ ]]; then
    if ((TEMP < 20)); then
        TEMP_ICON="${C}"
    elif ((TEMP < 40)); then
        TEMP_ICON="${G}"
    elif ((TEMP > 40)); then
        TEMP_ICON="${R}"
    fi
else
    TEMP_ICON=""
fi

# Architecture icon
cpu_arch=$(uname -m)
if [[ $cpu_arch == "aarch64" ]]; then
    cpu_arch_icon="󰻠"
else
    cpu_arch_icon="󰻟"
fi

# Pick icon based on battery level
if [[ "$BATTERY" =~ ^[0-9]+$ ]]; then
    if ((BATTERY < 20)); then
        BAT_ICON="${R} " # Empty
    elif ((BATTERY < 40)); then
        BAT_ICON="${Y} " # Low
    elif ((BATTERY < 60)); then
        BAT_ICON="${Y} " # Medium
    elif ((BATTERY < 80)); then
        BAT_ICON="${G} " # High
    else
        BAT_ICON="${G} " # Full
    fi
else
    BAT_ICON="${R} "
    BATTERY="N/A"
fi

if [[ $BATTERY_STATUS == "CHARGING" ]]; then
    CHARGE_ICON="${BOLD}${G}"
else
    CHARGE_ICON=""
fi

# Memory usage
IFS=' ' read -r USED TOTAL <<<"$(free -htm | awk '/Mem/ { print $3, $2 }')"

# ASCII logo
LOGO="
  ;,           ,;
   ';,.-----.,;'
  ,'           ',
 /    ${NC}O     O${G}    \\
|                 |
'-----------------'
"

clear

# print the logo
printf "%25s %b\n" "" "${G}${LOGO}${NC}"

echo -e "${NC}${BOLD}System Info:
${C} System          : ${G} ${NC}${DISTRO}
${C} Host            : ${G}󰍹 ${NC}${MODEL}
${C} Kernel          : ${G} ${NC}$(uname -r | grep -o '^[0-9]*\.[0-9]*\.[0-9]*')
${C} CPU             : ${G}󰍛 ${NC}${soc_details} (${G}${PROCESSOR_COUNT}${NC} vCPU)
${C} Architectures   : ${G}${cpu_arch_icon} ${NC}${cpu_arch^^}
${C} Termux Version  : ${G} ${NC}${TERMUX_VERSION}-${termux_build}${NC}
${C} Battery Level   : ${BAT_ICON}${NC}${BATTERY}%${NC} ${CHARGE_ICON}${NC}
${C} Memory          : ${G}󰘚 ${USED}${NC} used, ${TOTAL}${NC} total
${C} Temperature     : ${TEMP_ICON} ${TEMP}°C${NC}
"

# Disk usage bars
max_usage=95
bar_width=45

# Disk Usage header
printf "%b\n" "${BOLD}Disk Usage:${NC}"

# Get terminal width
cols=${COLUMNS:-$(stty size 2>/dev/null | awk '{print $2}')}
indent=1 # leading spaces in printf

# Calculate dynamic bar width
margin=2 # Space on each side of the bar
bar_width=$((cols - 2 * indent - 2 * margin))
# Ensure minimum width
bar_width=$((bar_width < 20 ? 20 : bar_width))

# Calculate dynamic mount-point width
trailer=20 # adjust this to match width of " used XX of YY"
mount_width=$((cols - indent - trailer))

# Iterate over filesystems and draw bars
while read -r _ size used _ usep mount; do
    pct=${usep%%%}
    used_width=$((pct * bar_width / 100))
    ((pct >= max_usage)) && bar_color=$R || bar_color=$G

    # build bar graphic
    bar="[${bar_color}"
    for ((i = 0; i < used_width; i++)); do bar+="#"; done
    bar+="${WHITE}${DIM}"
    for ((i = used_width; i < bar_width; i++)); do bar+="-"; done
    bar+="${UNDIM}]"

    # print filesystem usage with dynamic alignment
    printf "%*s%-*s used %-4s of %-4s\n" "$indent" "" "$mount_width" "$mount" "$used" "$size"
    # print bar with same indent
    printf "%*s%b\n" "$indent" "" "$bar"
done < <(df -H -t sdcardfs -t fuse -t fuse.rclone | tail -n +2)

