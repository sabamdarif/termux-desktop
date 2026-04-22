## :joystick: Learn about Pokémon GBA/NDS Romhack Dev Tools:

> Full documentation: [docs/romhack-tools.md](./romhack-tools.md)

#### :jigsaw: Packages Installed in Termux:

- **[make](https://www.gnu.org/software/make/):** Build automation for decomp projects
- **[nasm](https://www.nasm.us):** Assembler for x86/ARM source files
- **[clang](https://clang.llvm.org):** C/C++ compiler for native host-side tools
- **[perl](https://www.perl.org):** Symbol file generation and decomp scripting
- **[xdelta3](http://xdelta.org):** Create and apply binary ROM patches
- **[Pillow](https://python-pillow.org)** _(pip)_**:** Image processing for ROM graphics and sprites
- **[PyYAML](https://pyyaml.org)** _(pip)_**:** YAML parsing used by decomp build configs
- **[ndspy](https://ndspy.readthedocs.io)** _(pip)_**:** Read and write NDS ROM files from Python
- **[colorama](https://pypi.org/project/colorama/)** _(pip)_**:** Colored terminal output used by decomp Python tooling

#### :jigsaw: Packages Installed in the Linux Container (Debian / Ubuntu / Arch):

- **[devkitPro](https://devkitpro.org) — gba-dev / nds-dev:** ARM cross-compiler toolchain (`arm-none-eabi-gcc`), GBA and NDS libraries (libgba, libnds), and ROM-packaging tools (grit, ndstool)
- **build-essential / base-devel:** Native host C/C++ compiler required to build decomp host tools (e.g. gbagfx)
- **libpng-dev / libpng:** Required by gbagfx and other decomp tool compilations
- **[Porymap](https://huderlem.github.io/porymap/)** _(pre-built ARM64 binary)_**:** Visual map and tileset editor for Gen 3 decomp projects (pokeemerald / pokefirered / pokeruby)
- **[Poryscript](https://github.com/huderlem/poryscript)** _(pre-built ARM64 binary)_**:** High-level scripting compiler for Gen 3 decomp projects — translates `.pory` scripts to native pokeemerald script format

#### :nerd_face: How to use them?

- Edit your decomp project in **code-oss** as you would on any Linux desktop
- Open the **"devkitPro Shell"** entry from the desktop application menu, or type your distro name (e.g. `debian`) in a terminal
- Run `make` inside the shell — the ARM toolchain is already on `$PATH`
- The compiled `.gba` / `.nds` ROM is written back to your project folder in Termux `$HOME`
- Test the ROM with an Android emulator app (e.g. **[My Boy!](https://play.google.com/store/apps/details?id=com.fastemulator.gba)** for GBA, **[melonDS](https://play.google.com/store/apps/details?id=me.magnum.melonds)** for NDS)

---

## :hammer_and_wrench: Learn about terminal utilities:

#### :jigsaw: 1. Additional Packages to be Installed:

- **[nala](https://github.com/volitank/nala):** Nala is a front-end for apt
- **[bat](https://github.com/sharkdp/bat):** Better replacement of cat
- **[eza](https://github.com/eza-community/eza):** A modern, maintained replacement for ls
- **[fastfetch](https://github.com/fastfetch-cli/fastfetch):** Better replacement of neofetch
- **[zoxide](https://github.com/ajeetdsouza/zoxide):** A smarter cd command

#### :nerd_face: How to use them?

- **_cd_** is replaced with **_zoxide_** (_use the cd command it will use zoxide_)
- use **_apt_** command it will use **_nala_** (for APT only)
- use **_ls_** command it will use **_eza_**
- use **_neofetch_** command it will use **_fastfetch_**
- use **_cat_** command it will use **_bat_**

#### :boom: 2. Special Functions

- **extract:** Use extract command to extract any archive
- **ftext:** Searches for text in all files in the current folder
- **cpg:** Copy and go to the directory
- **mvg:** Move and go to the directory
- **mkdirg:** Create and go to the directory
- **tdconfig** Print your current termux-desktop configuration
- **pdappps** Open the folder where all the apps added by proot-distro are located
- **startssh** To start a ssh server (after starting ssh, it will print the ip and port which you need for the connection)
- **stopssh** To stop the ssh server
- **listfont** To list all font
- **largefile** To list large files
- **preview** use fzf to search file and preview text file
- **fnvim** use fzf to search for an file and open the directly in neovim
- **fvim** same as _fnvim_ but for vim
- **fkill** to fuzzy find and kill the process
- **myip** shows your ip address
- **speedtest** run a speedtest
- **backup**: Quick backup of a file or directory with timestamp
- **freplace**: Find and replace text in files
- **duf**: Show disk usage of directories in current path (top 20 largest)
- **note**: Quick note taking
- **findbig**: Find files larger than specified size (default >100M)
- **encrypt**: Encrypt files using OpenSSL AES-256-CBC encryption
- **decrypt**: Decrypt files that were encrypted with the encrypt function
- **checksum**: Calculate MD5, SHA1, and SHA256 checksums for files
- **cp2clip**: Copy any text content from a file to the clipboard
    ##### For more `cat $HOME/.aliases`

#### :jigsaw: 3. Special Programs (scripts):

- **termux-fastest-repo**: same as termux-change-repo but tests and chooses the fastest repo (only for apt)
- **termux-color**: A TUI tool to switch between color schemes with live preview.
- **termux-nf**: A simple script to install Nerd Fonts in Termux.
    - Ex. just run `termux-nf` and choose from the menu or run `termux-nf FONT_NAME` and it will install that font.

#### :magic_wand: 4. Other tweaks:

- Undo/Redo in ZSH:- `CTRL + Z` to undo & `CTRL + y` to redo
- Open the current buffer in your `$EDITOR` (e.g., neovim) Press `Ctrl+X` followed by `Ctrl+E` to trigger
- Magic Space:- Expands history expressions like `!!` or `!$` when you press space
- Enable zmv (Advanced Batch Rename/Move):-
    - `zmv '(*).log' '$1.txt'` Rename all .log to .txt
    - `zmv -w '*.log' '*.txt'` Same thing, simpler syntax
    - `zmv -n '(*).log' '$1.txt'` Dry run (preview changes)
    - `zmv -i '(*).log' '$1.txt'` Interactive mode (confirm each)

---

## :hammer_and_wrench: Openbox Keybindings Cheat Sheet

This document provides a list of keybindings used in Openbox for quick reference.

- <kbd>⊞</kbd> = Meta key / the Windows key

#### General Navigation

| **Keybinding**                                       | **Action**                          |
| ---------------------------------------------------- | ----------------------------------- |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>Left</kbd>   | Go to the previous desktop          |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>Right</kbd>  | Go to the next desktop              |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>Up</kbd>     | Go to the desktop above             |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>Down</kbd>   | Go to the desktop below             |
| <kbd>Shift</kbd> + <kbd>Alt</kbd> + <kbd>Left</kbd>  | Send window to the previous desktop |
| <kbd>Shift</kbd> + <kbd>Alt</kbd> + <kbd>Right</kbd> | Send window to the next desktop     |
| <kbd>Shift</kbd> + <kbd>Alt</kbd> + <kbd>Up</kbd>    | Send window to the desktop above    |
| <kbd>Shift</kbd> + <kbd>Alt</kbd> + <kbd>Down</kbd>  | Send window to the desktop below    |
| <kbd>⊞</kbd> + <kbd>F1</kbd>                         | Go to desktop 1                     |
| <kbd>⊞</kbd> + <kbd>F2</kbd>                         | Go to desktop 2                     |
| <kbd>⊞</kbd> + <kbd>F3</kbd>                         | Go to desktop 3                     |
| <kbd>⊞</kbd> + <kbd>F4</kbd>                         | Go to desktop 4                     |

#### Window Management

| **Keybinding**                                     | **Action**                    |
| -------------------------------------------------- | ----------------------------- |
| <kbd>⊞</kbd> + <kbd>Space</kbd>                    | Launch Rofi (launcher)        |
| <kbd>⊞</kbd> + <kbd>Shift</kbd> + <kbd>Space</kbd> | Launch Rofi (dashboard)       |
| <kbd>Alt</kbd> + <kbd>Tab</kbd>                    | Switch to the next window     |
| <kbd>⊞</kbd> + <kbd>Tab</kbd>                      | Switch to the next window     |
| <kbd>⊞</kbd> + <kbd>Left</kbd>                     | Unmaximize horizontally       |
| <kbd>⊞</kbd> + <kbd>Right</kbd>                    | Unmaximize horizontally       |
| <kbd>⊞</kbd> + <kbd>Up</kbd>                       | Maximize window               |
| <kbd>⊞</kbd> + <kbd>Down</kbd>                     | Unmaximize window             |
| <kbd>Alt</kbd> + <kbd>F4</kbd>                     | Close window                  |
| <kbd>Alt</kbd> + <kbd>Escape</kbd>                 | Lower window                  |
| <kbd>Alt</kbd> + <kbd>Space</kbd>                  | Open client menu              |
| <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>Tab</kbd> | Switch to the previous window |
| <kbd>⊞</kbd> + <kbd>Shift</kbd> + <kbd>Right</kbd> | Cycle windows to the right    |
| <kbd>⊞</kbd> + <kbd>Shift</kbd> + <kbd>Left</kbd>  | Cycle windows to the left     |
| <kbd>⊞</kbd> + <kbd>Shift</kbd> + <kbd>Up</kbd>    | Cycle windows upwards         |
| <kbd>⊞</kbd> + <kbd>Shift</kbd> + <kbd>Down</kbd>  | Cycle windows downwards       |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>M</kbd>    | Unminimize all windows        |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>T</kbd>    | Open terminal (aterm)         |

#### Window Movement and Resizing

| **Keybinding**                                      | **Action**                            |
| --------------------------------------------------- | ------------------------------------- |
| <kbd>⊞</kbd> + <kbd>Alt</kbd> + <kbd>Up</kbd>       | Move window up                        |
| <kbd>⊞</kbd> + <kbd>Alt</kbd> + <kbd>Down</kbd>     | Move window down                      |
| <kbd>⊞</kbd> + <kbd>Alt</kbd> + <kbd>Left</kbd>     | Move window left                      |
| <kbd>⊞</kbd> + <kbd>Alt</kbd> + <kbd>Right</kbd>    | Move window right                     |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>Right</kbd> | Resize window horizontally (increase) |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>Left</kbd>  | Resize window horizontally (decrease) |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>Down</kbd>  | Resize window vertically (increase)   |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>Up</kbd>    | Resize window vertically (decrease)   |

#### Miscellaneous

| **Keybinding**                                 | **Action**               |
| ---------------------------------------------- | ------------------------ |
| <kbd>⊞</kbd> + <kbd>D</kbd>                    | Toggle show desktop      |
| <kbd>Shift</kbd> + <kbd>⊞</kbd> + <kbd>1</kbd> | Send window to desktop 1 |
| <kbd>Shift</kbd> + <kbd>⊞</kbd> + <kbd>2</kbd> | Send window to desktop 2 |
| <kbd>Shift</kbd> + <kbd>⊞</kbd> + <kbd>3</kbd> | Send window to desktop 3 |
| <kbd>Shift</kbd> + <kbd>⊞</kbd> + <kbd>4</kbd> | Send window to desktop 4 |
| <kbd>Shift</kbd> + <kbd>⊞</kbd> + <kbd>5</kbd> | Send window to desktop 5 |

---

## :hammer_and_wrench: i3 Keybindings Cheat Sheet

# i3 Window Manager - Keybindings Reference

**Modifier Key:** <kbd>Alt</kbd>

---

## 🚀 Launch Applications

| Keybinding                         | Action                           |
| ---------------------------------- | -------------------------------- |
| <kbd>Alt</kbd> + <kbd>Return</kbd> | Open terminal (xfce4-terminal)   |
| <kbd>Alt</kbd> + <kbd>Space</kbd>  | Launch Rofi application launcher |
| <kbd>Alt</kbd> + <kbd>E</kbd>      | Open file manager (Thunar)       |
| <kbd>Alt</kbd> + <kbd>Q</kbd>      | Kill focused window              |

---

## 🎵 Music Player Controls

| Keybinding                                       | Action                          |
| ------------------------------------------------ | ------------------------------- |
| <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>P</kbd> | Toggle play/pause               |
| <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>N</kbd> | Next track                      |
| <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>B</kbd> | Previous track                  |
| <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>S</kbd> | Stop playback                   |
| <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>I</kbd> | Show "Now Playing" notification |
| <kbd>Alt</kbd> + <kbd>C</kbd>                    | Open MPV control menu (Rofi)    |
| <kbd>Alt</kbd> + <kbd>X</kbd>                    | Open MPV music menu (Rofi)      |

---

## 🪟 Window Navigation

| Keybinding                    | Action                 |
| ----------------------------- | ---------------------- |
| <kbd>Alt</kbd> + <kbd>J</kbd> | Focus left window      |
| <kbd>Alt</kbd> + <kbd>K</kbd> | Focus down window      |
| <kbd>Alt</kbd> + <kbd>L</kbd> | Focus up window        |
| <kbd>Alt</kbd> + <kbd>;</kbd> | Focus right window     |
| <kbd>Alt</kbd> + <kbd>←</kbd> | Focus left window      |
| <kbd>Alt</kbd> + <kbd>↓</kbd> | Focus down window      |
| <kbd>Alt</kbd> + <kbd>↑</kbd> | Focus up window        |
| <kbd>Alt</kbd> + <kbd>→</kbd> | Focus right window     |
| <kbd>Alt</kbd> + <kbd>A</kbd> | Focus parent container |

---

## 📦 Move Windows

| Keybinding                                       | Action            |
| ------------------------------------------------ | ----------------- |
| <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>J</kbd> | Move window left  |
| <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>K</kbd> | Move window down  |
| <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>L</kbd> | Move window up    |
| <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>;</kbd> | Move window right |
| <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>←</kbd> | Move window left  |
| <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>↓</kbd> | Move window down  |
| <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>↑</kbd> | Move window up    |
| <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>→</kbd> | Move window right |

---

## 🔲 Window Layouts

| Keybinding                                           | Action                              |
| ---------------------------------------------------- | ----------------------------------- |
| <kbd>Alt</kbd> + <kbd>H</kbd>                        | Split horizontally                  |
| <kbd>Alt</kbd> + <kbd>V</kbd>                        | Split vertically                    |
| <kbd>Alt</kbd> + <kbd>F</kbd>                        | Toggle fullscreen                   |
| <kbd>Alt</kbd> + <kbd>W</kbd>                        | Tabbed layout                       |
| <kbd>Alt</kbd> + <kbd>S</kbd>                        | Toggle split layout                 |
| <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>Space</kbd> | Toggle floating window              |
| <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>T</kbd>     | Toggle focus mode (tiling/floating) |

---

## 🔢 Workspace Management

### Switch to Workspace

| Keybinding                    | Workspace    |
| ----------------------------- | ------------ |
| <kbd>Alt</kbd> + <kbd>1</kbd> | Workspace 1  |
| <kbd>Alt</kbd> + <kbd>2</kbd> | Workspace 2  |
| <kbd>Alt</kbd> + <kbd>3</kbd> | Workspace 3  |
| <kbd>Alt</kbd> + <kbd>4</kbd> | Workspace 4  |
| <kbd>Alt</kbd> + <kbd>5</kbd> | Workspace 5  |
| <kbd>Alt</kbd> + <kbd>6</kbd> | Workspace 6  |
| <kbd>Alt</kbd> + <kbd>7</kbd> | Workspace 7  |
| <kbd>Alt</kbd> + <kbd>8</kbd> | Workspace 8  |
| <kbd>Alt</kbd> + <kbd>9</kbd> | Workspace 9  |
| <kbd>Alt</kbd> + <kbd>0</kbd> | Workspace 10 |

### Move Window to Workspace

| Keybinding                                       | Action               |
| ------------------------------------------------ | -------------------- |
| <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>1</kbd> | Move to workspace 1  |
| <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>2</kbd> | Move to workspace 2  |
| <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>3</kbd> | Move to workspace 3  |
| <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>4</kbd> | Move to workspace 4  |
| <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>5</kbd> | Move to workspace 5  |
| <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>6</kbd> | Move to workspace 6  |
| <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>7</kbd> | Move to workspace 7  |
| <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>8</kbd> | Move to workspace 8  |
| <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>9</kbd> | Move to workspace 9  |
| <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>0</kbd> | Move to workspace 10 |

---

## 🔧 System Controls

| Keybinding                                       | Action                     |
| ------------------------------------------------ | -------------------------- |
| <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>Z</kbd> | Reload i3 configuration    |
| <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>R</kbd> | Restart i3 (keeps session) |
| <kbd>Alt</kbd> + <kbd>R</kbd>                    | Enter resize mode          |

---

## 📏 Resize Mode

**Enter resize mode with <kbd>Alt</kbd> + <kbd>R</kbd>, then use:**

| Keybinding                             | Action           |
| -------------------------------------- | ---------------- |
| <kbd>J</kbd> or <kbd>←</kbd>           | Shrink width     |
| <kbd>K</kbd> or <kbd>↓</kbd>           | Grow height      |
| <kbd>L</kbd> or <kbd>↑</kbd>           | Shrink height    |
| <kbd>;</kbd> or <kbd>→</kbd>           | Grow width       |
| <kbd>Return</kbd> or <kbd>Escape</kbd> | Exit resize mode |
| <kbd>Alt</kbd> + <kbd>R</kbd>          | Exit resize mode |

---

## 🖱️ Mouse Controls

| Action                           | Description                     |
| -------------------------------- | ------------------------------- |
| <kbd>Alt</kbd> + **Left Click**  | Drag to move floating windows   |
| <kbd>Alt</kbd> + **Right Click** | Drag to resize floating windows |

---

## :hammer_and_wrench: How to update the icon pack or theme:

- Stop the desktop
- Go to the style preview section
- Find the style you installed
- Click on the `Style Details:` section
- Click on the links
- Download the latest archive file
- move them to termux `$HOME` folder
    > Ex. `mv path/to/archive_file_name $HOME`
- Now to move the right archive to the right folder
    - <b>For XFCE</b>
        - Themes folder: `$HOME/.themes`
        - Icons folder: `$HOME/.icons`
    - <b>For LXQT And OPENBOX</b>
        - Themes folder: `$PREFIX/share/themes`
        - Icons folder: `$PREFIX/share/icons`
- Backup the old themes/icons folders
    > Ex. `tar -czvf icons_backup.tar.gz folder1 folder2 .... && mv icons_backup.tar.gz $HOME/icons_backup.tar.gz`
- Remove old folders
    > Ex. `rm -rf folder1 folder2 ....`
- Extract the new archive
    > Ex. `tar -xzvf new_archive.tar.gz`
- Remove the archive
    > Ex. `rm new_archive.tar.gz`

##### or, run `setup-termux-desktop --update icon/theme /path/to/archive_file_name` (will be added soon...)

## :hammer_and_wrench: How to enable Vulkan in Chromium Browser

- `chrome://flags/#enable-vulkan` Enable this then relaunch chromium

---

## :hammer_and_wrench: How to use X11 display forwarding option

- Command to use:

```bash
gui --display IP_ADDRESS:DISPLAY_PORT
```

`ex: gui --display 192.0.2.1:0`

#### On Windows:

Run: `ifconfig`

```bash
Ethernet adapter Ethernet 8:

   Connection-specific DNS Suffix  . :
   Link-local IPv6 Address . . . . . : fe80::7f3c:6323:b82f:679b%30
   IPv4 Address. . . . . . . . . . . : 192.168.127.228                 # Desktop IP set in x11 session on android
   Subnet Mask . . . . . . . . . . . : 255.255.255.0
   Default Gateway . . . . . . . . . : 192.168.127.84                  # Android Phone IP
```

- Install:- `VcXsrc`
- Launch VcXsrc then set
    1. Open window without titlebar
    2. Start no client
    3. Disable access control

#### On Linux:

Run: `ip a | grep inet`

```bash
    inet 127.0.0.1/8 scope host lo
    inet6 ::1/128 scope host noprefixroute
    inet 192.168.255.88/24 brd 192.168.255.255 scope global dynamic noprefixroute wlp2s0 # Here 192.168.255.88 is the ip address
    inet6 fe80::7c82:230f:89fb:5b5b/64 scope link noprefixroute
    inet 192.168.122.1/24 brd 192.168.122.255 scope global virbr0
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0`
```

- Install `xserver-xephyr` (package name might be different on other Linux distro)
- Then run:

    ```bash
    xhost +
    ```

    ```bash
    Xephyr :1 -ac -screen 1920x1080 -listen tcp -nolisten unix -fullscreen
    ```

    `Here: :1 will set the display port so make sure you use the right display port on gui --display command`

- On termux:-

    `gui --display 192.168.127.228:0` or just `192.168.127.228`(then it will use the default port 0)
