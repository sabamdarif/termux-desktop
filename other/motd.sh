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
for zone in /sys/class/thermal/thermal_zone*/temp; do
  if [ -f "$zone" ]; then
    cpu=$(cat "$zone")
    break
  fi
done

# Convert temperature format
if [[ -n "$cpu" && "$cpu" =~ ^[0-9]+$ ]]; then
  TEMP=$((cpu / 1000)) # Some devices store temp in millidegrees
  [[ "$TEMP" -eq 0 ]] && TEMP=$((cpu / 100))
else
  TEMP="N/A"
fi
PROCESSOR_BRAND_NAME="$(getprop ro.soc.manufacturer | tr '[:lower:]' '[:upper:]')"
PROCESSOR_NAME="$(getprop ro.soc.model | tr '[:lower:]' '[:upper:]')"
HARDWARE="$(getprop ro.hardware | tr '[:lower:]' '[:upper:]')"
if [[ -n "$PROCESSOR_BRAND_NAME" && -n "$PROCESSOR_NAME" ]]; then
  soc_details="$PROCESSOR_BRAND_NAME $PROCESSOR_NAME"
else
  soc_details="$HARDWARE"
fi
PROCESSOR_COUNT=$(grep -ioP 'processor\t:' /proc/cpuinfo | wc -l)
if [[ "$TEMP" -lt "20" ]]; then
  FG="${C}"
elif [[ "$TEMP" -gt "20" && "$TEMP" -lt "60" ]]; then
  FG="${G}"
elif [[ "$TEMP" -gt "60" ]]; then
  FG="${R}"
fi

cpu_arch=$(uname -m)

if [[ "$cpu_arch" == "aarch64" ]]; then
  cpu_arch_icon="󰻠"
else
  cpu_arch_icon="󰻟"
fi
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
$C System          : $G  ${W}$DISTRO
$C Host            : $G  ${W}$MODEL
$C Kernel          : $G  ${W}$(uname -sr)
$C CPU             : $G  ${W}${soc_details} ($G$PROCESSOR_COUNT$W vCPU)
$C Architectures   : $G${cpu_arch_icon}  ${W}$(uname -m | tr '[:lower:]' '[:upper:]')
$C Termux Version  : $G  ${W}${TERMUX_VERSION}-${termux_build}$W
$C Memory          : $G  ${G}$USED$W used, $G$TOTAL$W total$W
$C Temperature     : $FG  ${TEMP}°c$W"

max_usage=95
bar_width=45

# disk usage: ignore zfs, squashfs & tmpfs
mapfile -t dfs < <(df -H -t sdcardfs -t fuse -t fuse.rclone | tail -n+2)
printf "\n${BOLD}Disk Usage:${W}\n"

for line in "${dfs[@]}"; do
  # get disk usage
  usage=$(echo "$line" | awk '{print $5}' | sed 's/%//')
  used_width=$((($usage * $bar_width) / 100))
  # color is green if usage < max_usage, else red
  if [ "${usage}" -ge "${max_usage}" ]; then
    color=$R
  else
    color=$G
  fi
  # print green/red bar until used_width
  bar="[${color}"
  for ((i = 0; i < $used_width; i++)); do
    bar+="#"
  done
  # print dimmmed bar until end
  bar+="${white}${dim}"
  for ((i = $used_width; i < $bar_width; i++)); do
    bar+="-"
  done
  bar+="${undim}]"
  # print usage line & bar
  echo "${line}" | awk '{ printf("%-30s used %+1s of %+4s\n", $6, $3, $2); }' | sed -e 's/^/  /'
  echo -e "${bar}" | sed -e 's/^/  /'
done
