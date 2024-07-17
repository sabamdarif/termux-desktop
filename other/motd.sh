#!/data/data/com.termux/files/usr/bin
W="\e[0;39m"
G="\e[1;32m"
C="\e[1;36m"
Y='\033[1;33m'
R="\e[1;31m"
BOLD='\033[1m'

if [[ -d /system/app/ && -d /system/priv-app ]]; then
    DISTRO="Android $(getprop ro.build.version.release)"
    MODEL="$(getprop ro.product.brand) $(getprop ro.product.model)"
fi
termux_build=$(echo "$TERMUX_APK_RELEASE" | awk '{print tolower($0)}' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1')
cpu=$(</sys/class/thermal/thermal_zone0/temp)
TEMP=$(echo $cpu | cut -c 1-2)
PROCESSOR_NAME=$(cat /proc/cpuinfo | grep Hardware | cut -d ' ' -f 2)
PROCESSOR_COUNT=$(grep -ioP 'processor\t:' /proc/cpuinfo | wc -l)

[[ "$TEMP" -lt "60" ]] && FG=${G}
[[ "$TEMP" -gt "60" ]] && FG=${Y}                      
[[ "$TEMP" -gt "75" ]] && FG=${R}

clear

LOGO="
  ;,           ,;
   ';,.-----.,;'
  ,'           ',
 /    ${W}O     O${G}    \\
|                 |
'-----------------'
"

# get free memory
IFS=" " read USED AVAIL TOTAL <<<$(free -htm | grep "Mem" | awk {'print $3,$7,$2'})
printf "      %+25s ${G}${LOGO}${W}"
echo -e "
${W}${BOLD}System Info:
$C Distro          : $W$DISTRO
$C Host            : $W$MODEL
$C Kernel          : $W$(uname -sr)
$C CPU             : $W$PROCESSOR_NAME ($G$PROCESSOR_COUNT$W vCPU)
$C Termux Version  : $G${TERMUX_VERSION}-${termux_build}$W
$C Memory          : $G$USED$W used, $G$TOTAL$W total$W
$C Temperature     : $G${TEMP}°c$W"

max_usage=95
bar_width=45

# disk usage: ignore zfs, squashfs & tmpfs
mapfile -t dfs < <(df -H -t sdcardfs -t fuse -t fuse.rclone | tail -n+2)
printf "\n${BOLD}Disk Usage:${W}\n"

for line in "${dfs[@]}"; do
    # get disk usage
    usage=$(echo "$line" | awk '{print $5}' | sed 's/%//')
    used_width=$((($usage*$bar_width)/100))
    # color is green if usage < max_usage, else red
    if [ "${usage}" -ge "${max_usage}" ]; then
        color=$R
    else
        color=$G
    fi
    # print green/red bar until used_width
    bar="[${color}"
    for ((i=0; i<$used_width; i++)); do
        bar+="#"
    done
    # print dimmmed bar until end
    bar+="${white}${dim}"
    for ((i=$used_width; i<$bar_width; i++)); do
        bar+="-"
    done
    bar+="${undim}]"
    # print usage line & bar
    echo "${line}" | awk '{ printf("%-30s used %+1s of %+4s\n", $6, $3, $2); }' | sed -e 's/^/  /'
    echo -e "${bar}" | sed -e 's/^/  /'
done
