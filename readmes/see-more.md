## :hammer_and_wrench:Learn about terminal utilities:

#### :jigsaw:1.Additional Packages to be Installed:
- **[nala](https://github.com/volitank/nala):** Nala is a front-end  for apt
- **[bat](https://github.com/sharkdp/bat):** Better replacement of cat
- **[eza](https://github.com/eza-community/eza):** A modern, maintained replacement for ls
- **[fastfetch](https://github.com/fastfetch-cli/fastfetch):** Better replacement of neofetch
- **[zoxide](https://github.com/ajeetdsouza/zoxide):** A smarter cd command

#### :nerd_face:How to use them ?
- ***cd*** is replaced with ***zoxide*** (*use the cd command it will use zoxide*)
- use ***pkg*** or ***apt*** command it will use ***nala*** (for APT only)
- use ***ls*** command it will use ***eza***
- use ***neofetch*** command it will use ***fastfetch***
- use ***cat*** command it will use ***bat***
#### :boom:2.Special Functions

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
- **fvim** same as *fnvim* but for vim
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
  ##### For more cat $HOME/.aliases

#### :jigsaw:3.Special Programs (scripts):-
- **termux-fastest-repo**: same like termux-chnage-repo but to test and then chose the fastest repo (only for apt)
- **termux-color**: A TUI tool to switch between color schemes with live preview.
- **termux-nf**: A simple script to install nerd font in termux.
    - Ex. just run `termux-nf` and chose from the menu or run `termux-nf FONT_NAME` and it will install that font.


---

## :hammer_and_wrench: Openbox Keybindings Cheat Sheet

This document provides a list of keybindings used in Openbox for quick reference.

- <kbd>⊞</kbd> = Meta key / the Windows key

#### General Navigation

| **Keybinding** | **Action** |
|----------------|------------|
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>Left</kbd> | Go to the previous desktop |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>Right</kbd> | Go to the next desktop |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>Up</kbd> | Go to the desktop above |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>Down</kbd> | Go to the desktop below |
| <kbd>Shift</kbd> + <kbd>Alt</kbd> + <kbd>Left</kbd> | Send window to the previous desktop |
| <kbd>Shift</kbd> + <kbd>Alt</kbd> + <kbd>Right</kbd> | Send window to the next desktop |
| <kbd>Shift</kbd> + <kbd>Alt</kbd> + <kbd>Up</kbd> | Send window to the desktop above |
| <kbd>Shift</kbd> + <kbd>Alt</kbd> + <kbd>Down</kbd> | Send window to the desktop below |
| <kbd>⊞</kbd> + <kbd>F1</kbd> | Go to desktop 1 |
| <kbd>⊞</kbd> + <kbd>F2</kbd> | Go to desktop 2 |
| <kbd>⊞</kbd> + <kbd>F3</kbd> | Go to desktop 3 |
| <kbd>⊞</kbd> + <kbd>F4</kbd> | Go to desktop 4 |

#### Window Management

| **Keybinding** | **Action** |
|----------------|------------|
| <kbd>⊞</kbd> + <kbd>Space</kbd> | Launch Rofi (launcher) |
| <kbd>⊞</kbd> + <kbd>Shift</kbd> + <kbd>Space</kbd> | Launch Rofi (dashboard) |
| <kbd>Alt</kbd> + <kbd>Tab</kbd> | Switch to the next window |
| <kbd>⊞</kbd> + <kbd>Tab</kbd> | Switch to the next window |
| <kbd>⊞</kbd> + <kbd>Left</kbd> | Unmaximize horizontally |
| <kbd>⊞</kbd> + <kbd>Right</kbd> | Unmaximize horizontally |
| <kbd>⊞</kbd> + <kbd>Up</kbd> | Maximize window |
| <kbd>⊞</kbd> + <kbd>Down</kbd> | Unmaximize window |
| <kbd>Alt</kbd> + <kbd>F4</kbd> | Close window |
| <kbd>Alt</kbd> + <kbd>Escape</kbd> | Lower window |
| <kbd>Alt</kbd> + <kbd>Space</kbd> | Open client menu |
| <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>Tab</kbd> | Switch to the previous window |
| <kbd>⊞</kbd> + <kbd>Shift</kbd> + <kbd>Right</kbd> | Cycle windows to the right |
| <kbd>⊞</kbd> + <kbd>Shift</kbd> + <kbd>Left</kbd> | Cycle windows to the left |
| <kbd>⊞</kbd> + <kbd>Shift</kbd> + <kbd>Up</kbd> | Cycle windows upwards |
| <kbd>⊞</kbd> + <kbd>Shift</kbd> + <kbd>Down</kbd> | Cycle windows downwards |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>M</kbd> | Unminimize all windows |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>T</kbd> | Open terminal (aterm) |

#### Window Movement and Resizing

| **Keybinding** | **Action** |
|----------------|------------|
| <kbd>⊞</kbd> + <kbd>Alt</kbd> + <kbd>Up</kbd> | Move window up |
| <kbd>⊞</kbd> + <kbd>Alt</kbd> + <kbd>Down</kbd> | Move window down |
| <kbd>⊞</kbd> + <kbd>Alt</kbd> + <kbd>Left</kbd> | Move window left |
| <kbd>⊞</kbd> + <kbd>Alt</kbd> + <kbd>Right</kbd> | Move window right |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>Right</kbd> | Resize window horizontally (increase) |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>Left</kbd> | Resize window horizontally (decrease) |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>Down</kbd> | Resize window vertically (increase) |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>Up</kbd> | Resize window vertically (decrease) |

#### Miscellaneous

| **Keybinding** | **Action** |
|----------------|------------|
| <kbd>⊞</kbd> + <kbd>D</kbd> | Toggle show desktop |
| <kbd>Shift</kbd> + <kbd>⊞</kbd> + <kbd>1</kbd> | Send window to desktop 1 |
| <kbd>Shift</kbd> + <kbd>⊞</kbd> + <kbd>2</kbd> | Send window to desktop 2 |
| <kbd>Shift</kbd> + <kbd>⊞</kbd> + <kbd>3</kbd> | Send window to desktop 3 |
| <kbd>Shift</kbd> + <kbd>⊞</kbd> + <kbd>4</kbd> | Send window to desktop 4 |
| <kbd>Shift</kbd> + <kbd>⊞</kbd> + <kbd>5</kbd> | Send window to desktop 5 |

---

## :hammer_and_wrench:How the update the icon pack or theme:

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
    - Themes folder :- `$HOME/.themes`
    - Icons folder :- `$HOME/.icons`
  - <b>For LXQT And OPENBOX</b>
    - Themes folder :- `$PREFIX/share/themes`
    -  Icons folder :- `$PREFIX/share/icons`
- Backup the old themes/icons folders
> Ex. `tar -czvf icons_backup.tar.gz folder1 folder2 .... && mv icons_backup.tar.gz $HOME/icons_backup.tar.gz`
- Remove old folders
> Ex. `rm -rf folder1 folder2 ....`
- Extract the new archive
> Ex. `tar -xzvf new_archive.tar.gz`
- Remove the archive
> Ex. `rm new_archive.tar.gz`

##### or, run `setup-termux-desktop --update icon/theme /path/to/archive_file_name` (will be added soon...)

## :hammer_and_wrench:How to enable Vulkan in Chromium Browswer

- `chrome://flags/#enable-vulkan` Enable this then relaunch chromium

---

## :hammer_and_wrench:How to use x11 display forwarding option

- Command to use:-
```bash
gui --display IP_ADDRESS:DISPLAY_PORT
```
`ex: gui --display 192.0.2.1:0`

#### On Windows:- 
`run:- ifconfig`
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


#### On Linux:- 

`run:- ip a | grep inet`

```bash
    inet 127.0.0.1/8 scope host lo
    inet6 ::1/128 scope host noprefixroute
    inet 192.168.255.88/24 brd 192.168.255.255 scope global dynamic noprefixroute wlp2s0 # Here 192.168.255.88 is the ip address
    inet6 fe80::7c82:230f:89fb:5b5b/64 scope link noprefixroute
    inet 192.168.122.1/24 brd 192.168.122.255 scope global virbr0
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0`
```
- Install `xserver-xephyr` (package name might be different on other Linux distro)
- Then run:- 
    ```bash
    xhost +
    ```
    ```bash
    Xephyr :1 -ac -screen 1920x1080 -listen tcp -nolisten unix -fullscreen
    ```
    `here:- :1 will set the display port so make sure you use the right display port on gui --display command`


- On termux:-

    `gui --display 192.168.127.228:0` or just `192.168.127.228`(then it will use the default port 0)
