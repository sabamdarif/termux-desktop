#!/data/data/com.termux/files/usr/bin/bash
#
# A simple script to create a login screen or MOTD in Termux.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#
# Author     : @sabamdarif
# License    : GPL-v3
# Description: Creates a custom login screen/MOTD for Termux.
# Part of    : sabamdarif/termux-desktop
# Repository : https://github.com/sabamdarif/termux-desktop
# Inspired by: https://github.com/Generator/termux-motd

NC=$'\e[0;39m'
G=$'\e[1;32m'
C=$'\e[1;36m'
R=$'\e[1;31m'
Y=$'\e[1;33m'
BOLD=$'\033[1m'
WHITE=$'\e[0;37m'
DIM=$'\e[2m'
UNDIM=$'\e[22m'

clear

#==============================================
# Logo
#==============================================
LOGO="
  ;,           ,;
   ';,.-----.,;'
  ,'           ',
 /    ${NC}O     O${G}    \\
|                 |
'-----------------'
"
printf "%25s %b\n" "" "${G}${LOGO}${NC}"

echo -e "${NC}${BOLD}System Info:${NC}"

#==============================================
# Android System Information
#==============================================
if [[ -d /system/app/ && -d /system/priv-app ]]; then
    DISTRO="Android $(getprop ro.build.version.release)"
    echo -e "${C} System          : ${G}   ${NC}${DISTRO}"

    MODEL="$(getprop ro.product.brand) $(getprop ro.product.model)"
    echo -e "${C} Host            : ${G}󰍹   ${NC}${MODEL}"
fi

#==============================================
# Kernel Version
#==============================================
echo -e "${C} Kernel          : ${G}   ${NC}$(uname -r | grep -o '^[0-9]*\.[0-9]*\.[0-9]*')"

#==============================================
# CPU Information
#==============================================
PROC_BRAND=$(getprop ro.soc.manufacturer | tr '[:lower:]' '[:upper:]')
PROC_MODEL=$(getprop ro.soc.model | tr '[:lower:]' '[:upper:]')
HARDWARE=$(getprop ro.hardware | tr '[:lower:]' '[:upper:]')

if [[ -n $PROC_BRAND && -n $PROC_MODEL ]]; then
    soc_details="$PROC_BRAND $PROC_MODEL"
else
    soc_details="$HARDWARE"
fi

PROCESSOR_COUNT=$(grep -c '^processor' /proc/cpuinfo)
echo -e "${C} CPU             : ${G}󰍛   ${NC}${soc_details} (${G}${PROCESSOR_COUNT}${NC} vCPU)"

#==============================================
# Architecture
#==============================================
cpu_arch=$(uname -m)
[[ $cpu_arch == "aarch64" ]] && cpu_arch_icon="󰻠" || cpu_arch_icon="󰻟"
echo -e "${C} Architectures   : ${G}${cpu_arch_icon}   ${NC}${cpu_arch^^}"

#==============================================
# Termux Version
#==============================================
termux_build="${TERMUX_APK_RELEASE,,}"
termux_build="${termux_build^}"
echo -e "${C} Termux Version  : ${G}   ${NC}${TERMUX_VERSION}-${termux_build}${NC}"

#==============================================
# Memory Usage
#==============================================
IFS=' ' read -r USED TOTAL <<<"$(free -htm | awk '/Mem/ { print $3, $2 }')"
echo -e "${C} Memory          : ${G}󰘚   ${USED}${NC} used, ${TOTAL}${NC} total"

#==============================================
# Battery Information (Background Process)
#==============================================
(
    if cmd package list packages --user 0 -e -f | sed 's/package://; s/\.apk=/\.apk /' | grep -q "com.termux.api"; then
        if ! command -v termux-api-start &>/dev/null; then
            echo "battery:N/A:N/A:false"
            exit
        fi
        BATTERY=$(termux-battery-status 2>/dev/null | jq -r '.percentage // "N/A"')
        BATTERY_STATUS=$(termux-battery-status 2>/dev/null | jq -r '.status // "UNKNOWN"')
        echo "battery:${BATTERY}:${BATTERY_STATUS}:true"
    else
        echo "battery:N/A:N/A:false"
    fi
) >"${TMPDIR}/battery_info.tmp" &
battery_pid=$!

#==============================================
# Temperature Reading
#==============================================
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
    TEMP=$(termux-battery-status 2>/dev/null | jq -r '.temperature // "N/A"' | cut -d'.' -f1)
else
    TEMP="N/A"
fi

if [[ $TEMP =~ ^[0-9]+$ ]]; then
    ((TEMP < 20)) && TEMP_ICON="${C}"
    ((TEMP >= 20 && TEMP < 40)) && TEMP_ICON="${G}"
    ((TEMP >= 40)) && TEMP_ICON="${R}"
else
    TEMP_ICON=""
fi
echo -e "${C} Temperature     : ${TEMP_ICON}   ${TEMP}°C${NC}"

#==============================================
# Wait for Battery Info with 400ms Timeout
#==============================================
timeout_duration=0.40
timeout_reached=false
sleep_interval=0.01
max_iterations=$(awk "BEGIN {print int($timeout_duration / $sleep_interval)}")

for ((i = 0; i < max_iterations; i++)); do
    if ! kill -0 $battery_pid 2>/dev/null; then
        # Process finished
        break
    fi
    sleep $sleep_interval
done

# Check if process is still running after timeout
if kill -0 $battery_pid 2>/dev/null; then
    # Timeout reached, kill the process
    kill -9 $battery_pid 2>/dev/null
    timeout_reached=true
fi

wait $battery_pid 2>/dev/null

if [[ "$timeout_reached" == false && -f ${TMPDIR}/battery_info.tmp ]]; then
    IFS=':' read -r _ BATTERY BATTERY_STATUS <"${TMPDIR}/battery_info.tmp"
    rm -rf "${TMPDIR}/battery_info.tmp"

    if [[ "$BATTERY" =~ ^[0-9]+$ ]]; then
        ((BATTERY < 20)) && BAT_ICON="${R} "
        ((BATTERY >= 20 && BATTERY < 40)) && BAT_ICON="${Y} "
        ((BATTERY >= 40 && BATTERY < 60)) && BAT_ICON="${Y} "
        ((BATTERY >= 60 && BATTERY < 80)) && BAT_ICON="${G} "
        ((BATTERY >= 80)) && BAT_ICON="${G} "
    else
        BAT_ICON="${R} "
        BATTERY="N/A"
    fi

    [[ $BATTERY_STATUS == "CHARGING" ]] && CHARGE_ICON="${BOLD}${G}" || CHARGE_ICON=""

    echo -e "${C} Battery Level   : ${BAT_ICON}  ${NC}${BATTERY}%${NC} ${CHARGE_ICON}${NC}"
else
    # Timeout reached or file not found - skip battery info
    rm -rf "${TMPDIR}/battery_info.tmp" 2>/dev/null
fi

#==============================================
# Disk Usage Information
#==============================================
echo ""
printf "%b\n" "${BOLD}Disk Usage:${NC}"

cols=${COLUMNS:-$(stty size 2>/dev/null | awk '{print $2}')}
indent=1
margin=2
bar_width=$((cols - 2 * indent - 2 * margin))
bar_width=$((bar_width < 20 ? 20 : bar_width))
trailer=20
mount_width=$((cols - indent - trailer))
max_usage=95

while read -r _ size used _ usep mount; do
    pct=${usep%%%}
    used_width=$((pct * bar_width / 100))
    ((pct >= max_usage)) && bar_color=$R || bar_color=$G

    bar="[${bar_color}"
    for ((i = 0; i < used_width; i++)); do bar+="#"; done
    bar+="${WHITE}${DIM}"
    for ((i = used_width; i < bar_width; i++)); do bar+="-"; done
    bar+="${UNDIM}]"

    printf "%*s%-*s used %-4s of %-4s\n" "$indent" "" "$mount_width" "$mount" "$used" "$size"
    printf "%*s%b\n" "$indent" "" "$bar"
done < <(df -H -t sdcardfs -t fuse -t fuse.rclone 2>/dev/null | tail -n +2)
