#!/data/data/com.termux/files/usr/bin/bash

R="$(printf '\033[1;31m')"
G="$(printf '\033[1;32m')"
Y="$(printf '\033[1;33m')"
B="$(printf '\033[1;34m')"
C="$(printf '\033[1;36m')"
W="$(printf '\033[0m')"
BOLD="$(printf '\033[1m')"

_check_termux() {
  if [[ $HOME != *termux* ]]; then
    echo "${R}[${R}☓${R}]${R}${BOLD}Please run it inside termux${W}"
    exit 0
  fi
}

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
readonly SCRIPT_DIR

_get_script_parameter_value() {
  local filename=$1
  local parameter=$2

  grep --only-matching -m 1 "$parameter=[^\";]*" "$filename" | cut -d "=" -f 2 | tr -d "'" | tr "|" ";" 2>/dev/null
}

_command_exists() {
  # This function checks whether a given command is available on the system.
  #
  # Parameters:
  #   - $1 (command_check): The name of the command to verify.

  local command_check=$1

  if command -v "$command_check" &>/dev/null; then
    return 0
  fi
  return 1
}

_print_success() {
  local msg
  msg="$1"
  echo "${R}[${G}✓${R}]${G} $msg${W}"
}

_print_failed() {
  local msg
  msg="$1"
  echo "${R}[${R}☓${R}]${R} $msg${W}"
}

_check_and_create_directory() {
  if [[ ! -d "$1" ]]; then
    mkdir -p "$1"
  fi
}

# first check then delete
_check_and_delete() {
  local file
  local files_folders
  for files_folders in "$@"; do
    for file in $files_folders; do
      if [[ -e "$file" ]]; then
        if [[ -d "$file" ]]; then
          rm -rf "$file" >/dev/null 2>&1
        elif [[ -f "$file" ]]; then
          rm "$file" >/dev/null 2>&1
        fi
      fi
    done
  done
}

# first check then backup
_check_and_backup() {
  local file
  local files_folders
  for files_folders in "$@"; do
    for file in $files_folders; do
      if [[ -e "$file" ]]; then
        local date_str
        date_str=$(date +"%d-%m-%Y")
        local backup="${file}-${date_str}.bak"
        if [[ -e "$backup" ]]; then
          echo "${R}[${C}-${R}]${G} Backup file ${C}${backup} ${G}already exists${W}"
          echo
        fi
        echo "${R}[${C}-${R}]${G} Backing up file ${C}$file${W}"
        mv "$1" "$backup"
      fi
    done
  done
}

_detact_package_manager() {
  source "/data/data/com.termux/files/usr/bin/termux-setup-package-manager"
  if [[ "$TERMUX_APP_PACKAGE_MANAGER" == "apt" ]]; then
    PACKAGE_MANAGER="apt"
  elif [[ "$TERMUX_APP_PACKAGE_MANAGER" == "pacman" ]]; then
    PACKAGE_MANAGER="pacman"
  else
    _print_failed "${C} Could not detact your package manager, Switching To ${C}pkg ${W}"
  fi
}

# will check if the package is already installed or not, if it installed then it will reinstall it and at the end it will print success/failed message
_package_install_and_check() {
  packs_list=($@)
  for package_name in "${packs_list[@]}"; do
    echo "${R}[${C}-${R}]${G}${BOLD} Processing package: ${C}$package_name ${W}"

    if [[ "$PACKAGE_MANAGER" == "pacman" ]]; then
      if pacman -Qi "$package_name" >/dev/null 2>&1; then
        continue
      fi

      if [[ $package_name == *"*"* ]]; then
        echo "${R}[${C}-${R}]${C} Processing wildcard pattern: $package_name ${W}"
        packages=$(pacman -Ssq "${package_name%*}" 2>/dev/null)
        for pkgs in $packages; do
          echo "${R}[${C}-${R}]${G}${BOLD} Installing matched package: ${C}$pkgs ${W}"
          pacman -Sy --noconfirm --overwrite '*' "$pkgs"
        done
      else
        pacman -Sy --noconfirm --overwrite '*' "$package_name"
      fi

    else
      if [[ $package_name == *"*"* ]]; then
        echo "${R}[${C}-${R}]${C} Processing wildcard pattern: $package_name ${W}"
        packages_by_name=$(apt-cache search "${package_name%*}" | awk "/^${package_name}/ {print \$1}")
        packages_by_description=$(apt-cache search "${package_name%*}" | grep -Ei "\b${package_name%*}\b" | awk '{print $1}')
        packages=$(echo -e "${packages_by_name}\n${packages_by_description}" | sort -u)
        for pkgs in $packages; do
          echo "${R}[${C}-${R}]${G}${BOLD} Installing matched package: ${C}$pkgs ${W}"
          if dpkg -s "$pkgs" >/dev/null 2>&1; then
            pkg reinstall "$pkgs" -y
          else
            pkg install "$pkgs" -y
          fi
        done
      else
        if dpkg -s "$package_name" >/dev/null 2>&1; then
          pkg reinstall "$package_name" -y
        else
          pkg install "$package_name" -y
        fi
      fi
    fi

    # Check installation success
    if [ $? -ne 0 ]; then
      echo "${R}[${C}-${R}]${G}${BOLD} Error detected during installation of: ${C}$package_name ${W}"
      if [[ "$PACKAGE_MANAGER" == "pacman" ]]; then
        pacman -Sy --overwrite '*' "$package_name"
        pacman -Sy --noconfirm "$package_name"
      else
        apt --fix-broken install -y
        dpkg --configure -a
        pkg install "$package_name" -y
      fi
    fi

    # Final verification
    if [[ $package_name != *"*"* ]]; then
      if [[ "$PACKAGE_MANAGER" == "pacman" ]]; then
        if pacman -Qi "$package_name" >/dev/null 2>&1; then
          _print_success "$package_name installed successfully"
        else
          _print_failed "$package_name installation failed ${W}"
        fi
      else
        if dpkg -s "$package_name" >/dev/null 2>&1; then
          _print_success "$package_name installed successfully"
        else
          _print_failed "$package_name installation failed ${W}"
        fi
      fi
    fi
  done
  echo ""
}

COMPATIBLE_FILE_MANAGERS=("caja" "pcmanfm-qt" "thunar")
FILE_MANAGER=""
INSTALL_DIR=""

_step_install_dependencies() {
  echo "${R}[${G}-${R}]${G} Installing the dependencies...${W}"

  # Core utilities
  _package_install_and_check "zenity xclip"

  # Archive handling
  _package_install_and_check "bzip2 gzip tar unzip zip xorriso"

  # Image processing
  _package_install_and_check "optipng imagemagick"

  # Document processing
  _package_install_and_check "ghostscript qpdf poppler"

  # Multimedia
  _package_install_and_check "ffmpeg"

  # File utilities
  _package_install_and_check "rdfind exiftool"

  # Other utilities
  _package_install_and_check "perl rhash pandoc p7zip xz-utils"

  # Fix ImageMagick PDF permissions
  local imagemagick_config="/data/data/com.termux/files/usr/etc/ImageMagick-7/policy.xml"
  if [[ -f "$imagemagick_config" ]]; then
    echo "${R}[${G}-${R}]${G} Fixing write permission with PDF in ImageMagick...${W}"
    sed -i 's/rights="none" pattern="PDF"/rights="read|write" pattern="PDF"/g' "$imagemagick_config"
    sed -i 's/".GiB"/"8GiB"/g' "$imagemagick_config"
  fi
}

_setup_file_manager() {
  local file_manager=""

  # Loop through compatible file managers.
  for file_manager in "${COMPATIBLE_FILE_MANAGERS[@]}"; do
    # Check if the file manager command exists.
    if _command_exists "$file_manager"; then
      case "$file_manager" in
      "caja")
        INSTALL_DIR="$HOME/.config/caja/scripts"
        FILE_MANAGER="caja"
        ;;
      "pcmanfm-qt")
        INSTALL_DIR="$HOME/.local/share/scripts"
        FILE_MANAGER="pcmanfm-qt"
        ;;
      "thunar")
        INSTALL_DIR="$HOME/.local/share/scripts"
        FILE_MANAGER="thunar"
        ;;
      esac

      # Create the installation directory if it doesn't exist.
      _check_and_create_directory "$INSTALL_DIR"

      # Exit the function once a file manager is successfully configured.
      return
    fi
  done

  # If no compatible file manager is found, print an error and exit.
  _print_failed "Error: could not find any compatible file managers!"
  exit 1
}

_step_install_shortcuts_gnome2() {
  echo "${R}[${G}-${R}]${G} Installing the keyboard shortcuts...${W}"

  local accels_file=$1
  mkdir --parents "$(dirname -- "$accels_file")"

  # Create a backup of older custom actions.
  _check_and_backup "$accels_file"
  _check_and_delete "$accels_file"

  {
    # Disable the shortcut for "OpenAlternate" (<control><shift>o).
    printf "%s\n" '(gtk_accel_path "<Actions>/DirViewActions/OpenAlternate" "")'
    # Disable the shortcut for "OpenInNewTab" (<control><shift>o).
    printf "%s\n" '(gtk_accel_path "<Actions>/DirViewActions/OpenInNewTab" "")'
    # Disable the shortcut for "Show Hide Extra Pane" (F3).
    printf "%s\n" '(gtk_accel_path "<Actions>/NavigationActions/Show Hide Extra Pane" "")'
    printf "%s\n" '(gtk_accel_path "<Actions>/ShellActions/Show Hide Extra Pane" "")'

    local filename=""
    while IFS="" read -r -d "" filename; do
      local install_keyboard_shortcut=""
      install_keyboard_shortcut=$(_get_script_parameter_value "$filename" "install_keyboard_shortcut")
      install_keyboard_shortcut=${install_keyboard_shortcut//Control/Primary}

      if [[ -n "$install_keyboard_shortcut" ]]; then
        # Escape slashes and spaces for Gnome shortcut paths.
        # shellcheck disable=SC2001
        filename=$(sed "s|/|\\\\\\\\s|g; s| |%20|g" <<<"$filename")
        printf "%s\n" '(gtk_accel_path "<Actions>/ScriptsGroup/script_file:\\s\\s'"$filename"'" "'"$install_keyboard_shortcut"'")'
      fi
    done < <(find -L "$INSTALL_DIR" -mindepth 2 -type f ! -path "*.git*" ! -path "*.assets*" -print0 2>/dev/null | sort --zero-terminated)

  } >"$accels_file"

  echo "${R}[${G}✓${R}]${G} Keyboard shortcuts installed successfully${W}"
}

_step_install_shortcuts_thunar() {
  echo "${R}[${G}-${R}]${G} Installing the keyboard shortcuts for Thunar...${W}"

  local accels_file=$1
  mkdir --parents "$(dirname -- "$accels_file")"

  # Create a backup of older custom actions.
  _check_and_backup "$accels_file"
  _check_and_delete "$accels_file"

  {
    # Default Thunar shortcuts.
    printf "%s\n" '(gtk_accel_path "<Actions>/ThunarActions/uca-action-1-1" "")'
    printf "%s\n" '(gtk_accel_path "<Actions>/ThunarActions/uca-action-4-4" "")'
    printf "%s\n" '(gtk_accel_path "<Actions>/ThunarActions/uca-action-3-3" "")'
    # Disable "<Primary><Shift>p".
    printf "%s\n" '(gtk_accel_path "<Actions>/ThunarActionManager/open-in-new-tab" "")'
    # Disable "<Primary><Shift>o".
    printf "%s\n" '(gtk_accel_path "<Actions>/ThunarActionManager/open-in-new-window" "")'
    # Disable "<Primary>e".
    printf "%s\n" '(gtk_accel_path "<Actions>/ThunarWindow/view-side-pane-tree" "")'

    local filename=""
    while IFS="" read -r -d "" filename; do
      local install_keyboard_shortcut=""
      install_keyboard_shortcut=$(_get_script_parameter_value "$filename" "install_keyboard_shortcut")
      install_keyboard_shortcut=${install_keyboard_shortcut//Control/Primary}

      if [[ -n "$install_keyboard_shortcut" ]]; then
        local name=""
        local submenu=""
        local unique_id=""
        name=$(basename -- "$filename")
        submenu=$(dirname -- "$filename" | sed "s|.*scripts/|Scripts/|g")
        unique_id=$(echo -n "$submenu$name" | md5sum | sed "s|[^0-9]*||g" | cut -c 1-8)

        printf "%s\n" '(gtk_accel_path "<Actions>/ThunarActions/uca-action-'"$unique_id"'" "'"$install_keyboard_shortcut"'")'
      fi
    done < <(find -L "$INSTALL_DIR" -mindepth 2 -type f ! -path "*.git*" ! -path "*.assets*" -print0 2>/dev/null | sort --zero-terminated)

  } >"$accels_file"
}

_step_install_shortcuts() {
  # Install keyboard shortcuts for specific file managers.

  case "$FILE_MANAGER" in
  "caja") _step_install_shortcuts_gnome2 "$HOME/.config/caja/accels" ;;
  "thunar") _step_install_shortcuts_thunar "$HOME/.config/Thunar/accels.scm" ;;
  esac
}

_step_install_menus_pcmanfm() {
  echo "${R}[${G}-${R}]${G} Installing PCManFM-Qt actions...${W}"

  local desktop_menus_dir="$HOME/.local/share/file-manager/actions"
  _check_and_create_directory "$desktop_menus_dir"
  _check_and_backup "$desktop_menus_dir"/*.desktop
  _check_and_delete "$desktop_menus_dir"/*.desktop

  # Create the 'Scripts.desktop' menu.
  {
    printf "%s\n" "[Desktop Entry]"
    printf "%s\n" "Type=Menu"
    printf "%s\n" "Name=Scripts"
    printf "%s" "ItemsList="
    find -L "$INSTALL_DIR" -mindepth 1 -maxdepth 1 -type d ! -path "*.git*" ! -path "*.assets*" -printf "%f\n" 2>/dev/null | sort | tr $'\n' ";" || true
    printf "\n"
  } >"${desktop_menus_dir}/Scripts.desktop"
  chmod +x "${desktop_menus_dir}/Scripts.desktop"

  # Create a '.desktop' file for each directory (for sub-menus).
  local filename=""
  local name=""
  local dir_items=""
  find -L "$INSTALL_DIR" -mindepth 1 -type d ! -path "*.git*" ! -path "*.assets*" -print0 2>/dev/null | sort --zero-terminated |
    while IFS= read -r -d "" filename; do
      name=${filename##*/}
      dir_items=$(find -L "$filename" -mindepth 1 -maxdepth 1 ! -path "*.git*" ! -path "*.assets*" -printf "%f\n" 2>/dev/null | sort | tr $'\n' ";" || true)
      if [[ -z "$dir_items" ]]; then
        continue
      fi

      {
        printf "%s\n" "[Desktop Entry]"
        printf "%s\n" "Type=Menu"
        printf "%s\n" "Name=$name"
        printf "%s\n" "ItemsList=$dir_items"

      } >"${desktop_menus_dir}/$name.desktop"
      chmod +x "${desktop_menus_dir}/$name.desktop"
    done

  # Create a '.desktop' file for each script.
  while IFS="" read -r -d "" filename; do
    name=${filename##*/}

    # Set the mime requirements.
    local par_recursive=""
    local par_select_mime=""
    par_recursive=$(_get_script_parameter_value "$filename" "par_recursive")
    par_select_mime=$(_get_script_parameter_value "$filename" "par_select_mime")

    if [[ -z "$par_select_mime" ]]; then
      local par_type=""
      par_type=$(_get_script_parameter_value "$filename" "par_type")

      case "$par_type" in
      "directory") par_select_mime="inode/directory" ;;
      "all") par_select_mime="all/all" ;;
      "file") par_select_mime="all/allfiles" ;;
      *) par_select_mime="all/allfiles" ;;
      esac
    fi

    if [[ "$par_recursive" == "true" ]]; then
      case "$par_select_mime" in
      "inode/directory") : ;;
      "all/all") : ;;
      "all/allfiles") par_select_mime="all/all" ;;
      *) par_select_mime+=";inode/directory" ;;
      esac
    fi

    par_select_mime="$par_select_mime;"
    # shellcheck disable=SC2001
    par_select_mime=$(sed "s|/;|/*;|g" <<<"$par_select_mime")

    local desktop_filename=""
    desktop_filename="${desktop_menus_dir}/${name}.desktop"
    {
      printf "%s\n" "[Desktop Entry]"
      printf "%s\n" "Type=Action"
      printf "%s\n" "Name=$name"
      printf "%s\n" "Profiles=scriptAction"
      printf "\n"
      printf "%s\n" "[X-Action-Profile scriptAction]"
      printf "%s\n" "MimeTypes=$par_select_mime"
      printf "%s\n" "Exec=bash \"$filename\" %F"
    } >"$desktop_filename"
    chmod +x "$desktop_filename"
  done < <(find -L "$INSTALL_DIR" -mindepth 2 -type f ! -path "*.git*" ! -path "*.assets*" -print0 2>/dev/null | sort --zero-terminated)

  echo "${R}[${G}✓${R}]${G} PCManFM-Qt menus installed successfully${W}"
}

_step_install_menus_thunar() {
  echo "${R}[${G}-${R}]${G} Installing Thunar actions...${W}"

  local menus_file="$HOME/.config/Thunar/uca.xml"
  local accels_file="$HOME/.config/Thunar/accels.scm"

  # Create directories if they don't exist
  mkdir -p "$(dirname "$menus_file")"

  # Backup existing files
  _check_and_backup "$menus_file"
  _check_and_backup "$accels_file"

  # First create the menu actions
  echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" >"$menus_file"
  echo "<actions>" >>"$menus_file"

  # Process each script file for menu actions
  while IFS= read -r -d '' script_file; do
    local menu_name=""
    local menu_path=""
    local unique_id=""

    menu_name=$(basename -- "$script_file")
    menu_path=$(dirname -- "$script_file" | sed "s|$INSTALL_DIR/||" | sed 's|/|/|g')
    menu_path="Scripts/$menu_path"
    unique_id=$(echo -n "$menu_path$menu_name" | md5sum | sed "s|[^0-9]*||g" | cut -c 1-8)

    # Add to uca.xml
    {
      echo "<action>"
      echo "    <icon></icon>"
      echo "    <name>$menu_name</name>"
      echo "    <submenu>$menu_path</submenu>"
      echo "    <unique-id>$unique_id</unique-id>"
      echo "    <command>bash &quot;$script_file&quot; %F</command>"
      echo "    <description></description>"
      echo "    <range></range>"
      echo "    <patterns>*</patterns>"
      echo "    <directories/>"
      echo "    <audio-files/>"
      echo "    <image-files/>"
      echo "    <text-files/>"
      echo "    <video-files/>"
      echo "    <other-files/>"
      echo "</action>"
    } >>"$menus_file"

  done < <(find -L "$INSTALL_DIR" -mindepth 2 -type f ! -path "*.git*" ! -path "*.assets*" -print0 2>/dev/null | sort --zero-terminated)

  echo "</actions>" >>"$menus_file"

  # Then set up the keyboard shortcuts
  _step_install_shortcuts_thunar "$accels_file"

  # Set proper permissions
  chmod 644 "$menus_file" "$accels_file"
}

_step_install_menus() {
  # Install menus for specific file managers.
  echo "${R}[${G}-${R}]${G} Installing file manager menus...${W}"

  case "$FILE_MANAGER" in
  "pcmanfm-qt")
    _step_install_menus_pcmanfm
    ;;
  "thunar")
    # First create menus, then shortcuts
    _step_install_menus_thunar
    _step_install_shortcuts_thunar "$HOME/.config/Thunar/accels.scm"
    ;;
  "caja")
    _step_install_shortcuts_gnome2 "$HOME/.config/caja/accels"
    ;;
  esac
}

_step_install_scripts() {
  local tmp_install_dir=""

  # 'Remove' previous scripts.
  echo "${R}[${G}-${R}]${G} Removing previous scripts...${W}"
  _check_and_delete "$INSTALL_DIR"

  echo "${R}[${G}-${R}]${G} Installing new scripts...${W}"
  _check_and_create_directory "$INSTALL_DIR"

  # Copy the script files.
  cp -r "$SCRIPT_DIR"/* "$INSTALL_DIR"

  # Set file permissions.
  echo "${R}[${G}-${R}]${G} Setting file permissions...${W}"
  find -L "$INSTALL_DIR" -type f ! -path "*.git*" ! -exec chmod -x -- {} \;
  find -L "$INSTALL_DIR" -mindepth 2 -type f ! -path "*.git*" ! -path "*.assets*" -exec chmod +x -- {} \;
}

_step_close_filemanager() {
  echo "${R}[${G}-${R}]${G} Closing the file manager to reload its configurations...${W}"

  case "$FILE_MANAGER" in
  "caja" | "thunar")
    if pgrep -x "$FILE_MANAGER" &>/dev/null; then
      $FILE_MANAGER -q &>/dev/null || true &
    else
      echo "${R}[${G}-${R}]${Y} No running instance of $FILE_MANAGER found."
    fi
    ;;
  "pcmanfm-qt")
    if pgrep -x "$FILE_MANAGER" &>/dev/null; then
      killall "$FILE_MANAGER" &>/dev/null || true &
    else
      echo "${R}[${G}-${R}]${Y} No running instance of $FILE_MANAGER found."
    fi
    ;;
  *)
    _print_failed "Unknown file manager: $FILE_MANAGER"
    ;;
  esac
}

_check_files_copied_successfully() {
  local success=true
  local item

  for item in "$SCRIPT_DIR"/*; do
    local target="$INSTALL_DIR/$(basename "$item")"
    if [[ ! -e "$target" ]]; then
      echo "${R}[!] Missing: $target${W}"
      success=false
    fi
  done

  if $success; then
    _print_success "All files and folders have been copied successfully to $INSTALL_DIR"
  else
    _print_failed "Some files or folders are missing in $INSTALL_DIR"
  fi
}

main() {
  echo "${R}[${G}*${R}]${G} Starting installation...${W}"

  # First check and setup file manager
  _setup_file_manager || {
    _print_failed "Failed to setup file manager"
    exit 1
  }

  # Then install scripts to $INSTALL_DIR
  _step_install_scripts || {
    _print_failed "Failed to install scripts"
    exit 1
  }

  # After scripts are copied, install menus and shortcuts
  _step_install_menus || {
    _print_failed "Failed to install menus"
    exit 1
  }

  # Finally restart the file manager
  _step_close_filemanager || {
    _print_failed "Failed to restart file manager"
    exit 1
  }

  _check_files_copied_successfully

  _print_success "Installation completed successfully!"
  echo "${R}[${G}*${R}]${G} Please restart your file manager to see the changes${W}"
}

_check_termux
_detact_package_manager
_step_install_dependencies
main
