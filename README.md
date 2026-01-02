<div align="center">

# Termux Desktop

#### Easily Install Termux Native GUI Desktop

</div>
<div align="center">

![GitHub stars](https://img.shields.io/github/stars/sabamdarif/termux-desktop?style=for-the-badge) ![GitHub issues](https://img.shields.io/github/issues/sabamdarif/termux-desktop?color=violet&style=for-the-badge) ![GitHub repo size](https://img.shields.io/github/repo-size/sabamdarif/termux-desktop?style=for-the-badge) ![GitHub License](https://img.shields.io/github/license/sabamdarif/termux-desktop?style=for-the-badge)

![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/sabamdarif/termux-desktop/total?style=for-the-badge)

</div>

---

## Key Features:

- :books: **Easy Setup:** Easy-to-follow installation process
- :desktop_computer: **Desktop Styles:** Supports Xfce, LXQt, and Openbox... others with beautiful themes
- :mechanical_arm: **Hardware Acceleration:** It will install all the drivers in order to get hardware acceleration working under termux
- :paperclips: **GUI Access:**
    - Termux:X11 (Default)
    - VNC (vnc is optional and only available via the custom install section)
- :package: **Package Management:**
    - APT (Termux's default and recommended)
    - [PACMAN](https://youtu.be/ditNvG5Nxj0) (pacman may be buggy, not well tested)
- :shopping: **App Store:** An appstore to install apps
- :package: **Container** It lets you use a proot/chroot distro as a container to install more apps than Termux normally supports
- And a lot more, just choose the custom install option during the setup and see what you can do

---

### Quick Navigation

<div align="center">

**:package: [Distro Containers](/docs/proot-container.md) • :mechanical_arm: [Hardware Acceleration](/docs/hw-acceleration.md) • :wine_glass: [Wine](/docs/wine.md#wine_glasslearn-about-wine) • :bulb: [Others](/docs/see-more.md)**

</div>

---

## Getting Started:

##### 1. Ensure Requirements Are Met:

> [!NOTE]
> **This Only Works On Termux From GitHub Or F-Droid.**
> **Avoid using Termux from Google Play that doesn't work due to API limitations.**

- Android 8+ device
- **[Termux](https://termux.dev/en/)** (download from [GitHub](https://github.com/termux/termux-app/releases) or [F-Droid](https://f-droid.org/en/packages/com.termux/))
- **[Termux:X11](https://github.com/termux/termux-x11/releases)**
- **[Termux-API](https://github.com/termux/termux-api/releases)**
- Minimum 2GB of RAM _(3GB recommended)_
- 1.5-2GB of Internet data
- 3-4GB of free storage
- Root: Optional _(only for chroot-distro)_
- VNC Client _(Optional)_. Use:- [RealVNC](https://play.google.com/store/apps/details?id=com.realvnc.viewer.android) / [NetHunter Kex](https://store.nethunter.com/en/packages/com.offsec.nethunter.kex/)

##### 2. Currently supported Desktop Environments and Window Managers:

> [!TIP]
> Click on the Blue links to see all the available Styles for that De/Wm

| Desktop Environments         | Window Managers                    |
| ---------------------------- | ---------------------------------- |
| [Xfce](/docs/xfce_styles.md) | [Openbox](/docs/openbox_styles.md) |
| [LXQt](/docs/lxqt_styles.md) | [i3](/docs/i3_styles.md)           |
| MATE                         | dwm                                |
| GNOME                        | bspwm                              |
| Cinnamon                     | Awesome                            |
|                              | Fluxbox                            |
|                              | IceWM                              |
|                              | WMaker                             |

##### 3. Start Installation:

> Full Installation YouTube Video Guide:- [Here](https://youtu.be/SlR9f9hl5CQ?si=7O13ZAzdAnB_wwWw)

> [!IMPORTANT]
> **Fresh installations are recommended for best results.**
> **If you are on Android 12 or higher, first disable Phantom Process Killer Guide:-** [Here](https://github.com/atamshkai/Phantom-Process-Killer)

```bash
bash <(curl -Lf https://raw.githubusercontent.com/sabamdarif/termux-desktop/main/setup-termux-desktop)
```

> [!TIP]
> You can also do a lite install which will not install all the optional packages. To do that, first run `export LITE=true` or `export LITE=1`, then run the installer

##### 4. Usage Instructions:

- Commands for starting and stopping Termux:X11 and VNC sessions are provided below.

---

## Command Reference:

### Start Termux:X11

```bash
tx11start [options]
```

Options:

- `--xstartup`: Start the user-specified xstartup.
- `--nogpu`: Disable GPU acceleration.
- `--legacy`: Enable legacy drawing.
- `--nodbus`: Start without using dbus-launch.
- Combine options for specific configurations (e.g., `tx11start --nogpu --legacy`).
- `--help`: Show help.

<details>
<summary>Full Example:</summary>

- `tx11start` _to start Termux:X11 with gpu acceleration_
- `tx11start --xstartup cinnamon-session` _to start cinnamon even if you setup with xfce or anything else_
- `tx11start --nogpu` _to start Termux:X11 without gpu acceleration_
- `tx11start --nogpu --legacy` _to start Termux:X11 without gpu acceleration and *-legacy-drawing*_
- `tx11start --nodbus` _to start Termux:X11 without dbus-launch_
- `tx11start --nodbus --nogpu` _to start Termux:X11 without gpu acceleration and dbus_
- `tx11start --nodbus --nogpu --legacy` _to start Termux:X11 without gpu acceleration and dbus and with *-legacy-drawing*_
- `tx11start --nodbus --legacy` _to start Termux:X11 without dbus and use *-legacy-drawing* (nodbus and gpu)_
- `tx11start --legacy` _to start Termux:X11 with *-legacy-drawing* (with dbus and gpu)_
- `tx11start --debug --OTHER-PARAMETERS` _To see log of that command_
    > tx11start --debug --nogpu _To see tx11start --nogpu's log_

</details>

### Stop Termux:X11

```bash
tx11stop [-f]
```

Options:

- `-f`: Force stop.
- `--help`: Show help.

### Start VNC

```bash
vncstart [options]
```

Options:

- `--nogpu`: Disable GPU acceleration.
- `--help`: Show help.

### Stop VNC

```bash
vncstop [-f]
```

Options:

- `-f`: Force stop.
- `--help`: Show help.

### GUI Commands

```bash
gui [options]
```

Options:

- `--start`: Start GUI (use `vnc` or `tx11` as arguments).
- `--display`: Launch the current desktop environment on another X11 display server over the same network.
- `--stop`: Stop GUI.
- `--kill`: Stop all GUI sessions.
- `--help`: Show help.

<details>
<summary>Full Example:</summary>

##### If you select only one of them to access gui

- `gui --start / gui -l` _to start Termux gui_
- `gui --stop / gui -s` _to stop gui_
- `gui --display / gui -d` `<IP_ADDRESS>:<DISPLAY_PORT>` _To launch the current desktop environment on another X11 display server over the same network_

##### If you select both for gui access

- `gui -l / --start` `vnc` _to start VNC_
- `gui -l / --start` `tx11` _to start Termux:X11_
- `gui -s / --stop` `vnc` _to stop VNC_
- `gui -s / --stop` `tx11` _to stop Termux:X11_
- `gui -k / --kill / -kill` _to kill both vncserver and Termux:x11 At Once_
- `gui --display / gui -d` `<IP_ADDRESS>:<DISPLAY_PORT>` _To launch the current desktop environment on another X11 display server over the same network_
    - for more click :- [Here](https://github.com/sabamdarif/termux-desktop/blob/main/docs/see-more.md#hammer_and_wrenchhow-to-use-x11-display-forwarding-option)

</details>

### Setup Commands

```bash
setup-termux-desktop [options]
```

Options:

- `--change style`: Change desktop style.
- `--change hw`: Modify hardware acceleration settings.
- `--reset`: Reset all changes.
- `--remove`: Uninstall Termux Desktop.
- `--local-config`: Start the installation from a pre-made config file.
- `--help`: Show help.

<details>
<summary>Full Example:</summary>

- `setup-termux-desktop --change style` _To Change Desktop Style_
- `setup-termux-desktop --change hw` _To Change Hardware Acceleration Method_
- `setup-termux-desktop --change pd` _To Change Installed Proot-Distro_
- `setup-termux-desktop --change autostart` _To change autostart behaviour_
- `setup-termux-desktop --change display` _To change termux:x11 display port_
- `setup-termux-desktop --change de` _To switch between different desktop environment or window manager_
  <br>

- `setup-termux-desktop --reinstall icons / themes /config` _To Reinstall Icons / Themes / Config_
- `setup-termux-desktop --reinstall icons,themes,..etc` _To Reinstall Them At Once_
  <br>

- `setup-termux-desktop --reset` _To Reset All Changes Made By This Script Without Uninstalling The Packages_
  <br>

- `setup-termux-desktop --remove / -r` _To Remove Termux Desktop_
  <br>

- `setup-termux-desktop --local-config / -config` _Start the installation from a pre-made config file_ > Each time you install the desktop environment or make some changes using the script it writes all your config to the `/data/data/com.termux/files/usr/etc/termux-desktop/configuration.conf` file. Copy that somewhere else, so next time when you want to install the desktop environment with that old config all you have to do is `setup-termux-desktop --local-config /path/to/configuration.conf`
  <br>

- `setup-termux-desktop --debug` **(At the start)** _To generate a log file for any of the above commands_
    - `setup-termux-desktop --debug --install` _To create a log of whole installation process_

</details>

---

## Associated Repos:

- [Termux-AppStore](https://github.com/sabamdarif/Termux-AppStore)
  License: GPL

- [chroot-distro](https://github.com/sabamdarif/chroot-distro)
  License: GPL

---

## License

This project is licensed under the [GNU General Public License v3.0](https://choosealicense.com/licenses/gpl-3.0/).

---

## Acknowledgments:

Special thanks to:

- [LinuxDroidMaster/Termux-Desktops](https://github.com/LinuxDroidMaster/Termux-Desktops)
- [phoenixbyrd/Termux_XFCE](https://github.com/phoenixbyrd/Termux_XFCE)
- [Yisus7u7/termux-desktop-xfce](https://github.com/JesusChapman/termux-desktop-xfce)
- [adi1090x/termux-desktop](https://github.com/adi1090x/termux-desktop)
- [Generator/termux-motd](https://github.com/Generator/termux-motd)
- [ar37-rs/virgl-angle](https://github.com/ar37-rs/virgl-angle)
- [mayTermux/myTermux](https://github.com/mayTermux/myTermux)
- [catppuccin](https://github.com/catppuccin)
- [MastaG/mesa-turnip-ppa](https://github.com/MastaG/mesa-turnip-ppa)

---

**If you enjoy this project, consider giving it a star!** :star2:

---

## Support the Project

If you find Termux Desktop useful and would like to support its development, consider buying me a coffee! Your support helps me maintain and improve this project.

- **USDT (BEP20,ERC20):-** `0x1d216cf986d95491a479ffe5415dff18dded7e71`
- **USDT (TRC20):-** `TCjRKPLG4BgNdHibt2yeAwgaBZVB4JoPaD`
- **BTC:-** `13Q7xf3qZ9xH81rS2gev8N4vD92L9wYiKH`
- **DOGE (dogecoin):-** `DJkMCnBAFG14TV3BqZKmbbjD8Pi1zKLLG6`
- **ETH (ERC20):-** `0x1d216cf986d95491a479ffe5415dff18dded7e71`

_Every contribution, no matter how small, helps keep this project alive and growing! ❤️_

---

Join the conversation: [Telegram Chat](https://t.me/hello_android_0).
