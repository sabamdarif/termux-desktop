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
- **fcd** use fzf to search directories and cd into them

##### For more cat $HOME/.aliases
---

## :hammer_and_wrench:Openbox Keybindings Cheat Sheet

This document provides a list of keybindings used in Openbox for quick reference.

#### General Navigation

| **Keybinding**              | **Action**                                 |
|-----------------------------|--------------------------------------------|
| `Ctrl + Alt + Left`          | Go to the previous desktop                 |
| `Ctrl + Alt + Right`         | Go to the next desktop                     |
| `Ctrl + Alt + Up`            | Go to the desktop above                    |
| `Ctrl + Alt + Down`          | Go to the desktop below                    |
| `Shift + Alt + Left`         | Send window to the previous desktop        |
| `Shift + Alt + Right`        | Send window to the next desktop            |
| `Shift + Alt + Up`           | Send window to the desktop above           |
| `Shift + Alt + Down`         | Send window to the desktop below           |
| `Win + F1`                   | Go to desktop 1                            |
| `Win + F2`                   | Go to desktop 2                            |
| `Win + F3`                   | Go to desktop 3                            |
| `Win + F4`                   | Go to desktop 4                            |

#### Window Management

| **Keybinding**              | **Action**                                 |
|-----------------------------|--------------------------------------------|
| `Win + Space`                | Launch Rofi (launcher)                     |
| `Win + Shift + Space`        | Launch Rofi (dashboard)                    |
| `Alt + Tab`                  | Switch to the next window                  |
| `Win + Tab`                  | Switch to the next window                  |
| `Win + Left`                 | Unmaximize horizontally                    |
| `Win + Right`                | Unmaximize horizontally                    |
| `Win + Up`                   | Maximize window                            |
| `Win + Down`                 | Unmaximize window                          |
| `Alt + F4`                   | Close window                               |
| `Alt + Escape`               | Lower window                               |
| `Alt + Space`                | Open client menu                           |
| `Alt + Shift + Tab`          | Switch to the previous window              |
| `Win + Shift + Right`        | Cycle windows to the right                 |
| `Win + Shift + Left`         | Cycle windows to the left                  |
| `Win + Shift + Up`           | Cycle windows upwards                      |
| `Win + Shift + Down`         | Cycle windows downwards                    |
| `Ctrl + Alt + M`             | Unminimize all windows                     |
| `Ctrl + Alt + T`             | Open terminal (aterm)                      |

#### Window Movement and Resizing

| **Keybinding**              | **Action**                                 |
|-----------------------------|--------------------------------------------|
| `Win + Alt + Up`             | Move window up                            |
| `Win + Alt + Down`           | Move window down                          |
| `Win + Alt + Left`           | Move window left                          |
| `Win + Alt + Right`          | Move window right                         |
| `Ctrl + Alt + Right`         | Resize window horizontally (increase)     |
| `Ctrl + Alt + Left`          | Resize window horizontally (decrease)     |
| `Ctrl + Alt + Down`          | Resize window vertically (increase)       |
| `Ctrl + Alt + Up`            | Resize window vertically (decrease)       |

#### Miscellaneous

| **Keybinding**              | **Action**                                 |
|-----------------------------|--------------------------------------------|
| `Win + D`                   | Toggle show desktop                        |
| `Shift + Win + 1`           | Send window to desktop 1                   |
| `Shift + Win + 2`           | Send window to desktop 2                   |
| `Shift + Win + 3`           | Send window to desktop 3                   |
| `Shift + Win + 4`           | Send window to desktop 4                   |
| `Shift + Win + 5`           | Send window to desktop 5                   |

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