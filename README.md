<div align="center">

# Termux Desktop

#### Easily Install Termux GUI Desktop
</div>
<div align="center">

![GitHub stars](https://img.shields.io/github/stars/sabamdarif/termux-desktop?style=for-the-badge) ![GitHub forks](https://img.shields.io/github/forks/sabamdarif/termux-desktop?color=teal&style=for-the-badge) ![GitHub issues](https://img.shields.io/github/issues/sabamdarif/termux-desktop?color=violet&style=for-the-badge) ![GitHub repo size](https://img.shields.io/github/repo-size/sabamdarif/termux-desktop?style=for-the-badge) ![GitHub License](https://img.shields.io/github/license/sabamdarif/termux-desktop?style=for-the-badge)

</div>

---

## Key Features:

- :books: **Easy Setup:** Easy-to-follow installation process.
- :desktop_computer: **Desktop Styles:** Supports **XFCE**, **LXQt**, and **OPENBOX**... with beautiful themes.
- :mechanical_arm: **Hardware Acceleration:** It will install all the drivers in order to It will install all the drivers in order to get hardware acceleration working under termux.
- :paperclips: **GUI Access:** Supports Termux:X11 and VNC (vnc is optional).
- :package: **Package Management:** Compatible with both APT and [PACMAN](https://youtu.be/ditNvG5Nxj0) (pacman isn't well tested, so there might be some issues).
- :shopping: **App Store:** A appstore to install apps from termux and suppoted proot-distro.
- :package: **Apps** Normally, you're limited to apps that are supported by Termux, but it have a option for installing apps like LibreOffice via proot-distro and use them as a native app.
- And a lot more...

---

## Getting Started:

##### 1. Ensure Requirements Are Met:
   - Android 8+ device
   - **[Termux](https://termux.dev/en/)** (download from [GitHub](https://github.com/termux/termux-app/releases) or [F-Droid](https://f-droid.org/en/packages/com.termux/))
      >NOTE: This Only Works On Termux From Github Or Fdroid

     > Avoid using Termux from Google Play due to API limitations.
   - **[Termux:X11](https://github.com/termux/termux-x11/releases)**
   - **[Termux-API](https://github.com/termux/termux-api/releases)**
   - Minimum 2GB of RAM (3GB recommended)
   - 1.5-2GB of Internet data
   - 3-4GB of free storage
   - VNC Client [RealVNC](https://play.google.com/store/apps/details?id=com.realvnc.viewer.android) or [NetHunter Kex](https://store.nethunter.com/en/packages/com.offsec.nethunter.kex/) _(Optional)_

##### 2. Explore Desktop Styles:
   - **[XFCE](/readmes/xfce_styles.md)**
   - **[LXQt](/readmes/lxqt_styles.md)**
   - **[OPENBOX](/readmes/openbox_styles.md)**
   - **[MATE](/readmes/mate_styles.md)**

##### 3. Currently supported Desktop Environments and Window Managers:

###### **Desktop Environments**
- **Xfce**
- **LXQt**
- **MATE**
- **GNOME**

###### **Window Managers**
- **Openbox**
- **i3**
- **dwm**
- **bspwm**
- **Awesome**
- **Fluxbox**
- **IceWM**

##### 4. Hardware Acceleration and Distro Container:
   - Learn more about [hardware acceleration](/readmes/hw-acceleration.md).
   - Check out [distro container usage](/readmes/proot-container.md).

##### 5. Start Installation: 
> Full Installation YouTube Video Guide:- [Here](https://youtu.be/SlR9f9hl5CQ?si=7O13ZAzdAnB_wwWw)

> **Note: Fresh installations are recommended for best results.**

> **Note: If you are in android 12 or higher then first disable Phantom Process Killer Guide:-** [Here](https://github.com/atamshkai/Phantom-Process-Killer)
   ```bash
   curl -Lf https://raw.githubusercontent.com/sabamdarif/termux-desktop/main/setup-termux-desktop -o setup-termux-desktop && chmod +x setup-termux-desktop && ./setup-termux-desktop
   ```

- You can also do a lite install which will not install all the optional packages to do that run the install this `LITE=true ./setup-termux-desktop` or `LITE=1  ./setup-termux-desktop` instead of just running `./setup-termux-desktop`

##### 6. Usage Instructions:
   - Commands for starting and stopping Termux:X11 and VNC sessions are provided below.

---

## Command Reference:

### Start Termux:X11
```bash
tx11start [options]
```
Options:
- `--nogpu`: Disable GPU acceleration.
- `--legacy`: Enable legacy drawing.
- `--nodbus`: Disable DBus.
- Combine options for specific configurations (e.g., `tx11start --nogpu --legacy`).
- `--help`: To show help.

<details>
<summary>Full Example:</summary>

- `tx11start` *to star Termux:11 with gpu acceleration*
- `tx11start --nogpu` *to star Termux:11 without gpu acceleration*
- `tx11start --nogpu --legacy` *to star Termux:11 without gpu acceleration and _-legacy-drawing_*
- `tx11start --nodbus` *to star Termux:11 without dbus*
- `tx11start --nodbus --nogpu` *to star Termux:11 without gpu acceleration and dbus*
- `tx11start --nodbus --nogpu --legacy` *to star Termux:11 without gpu acceleration and dbus and with _-legacy-drawing_*
- `tx11start --nodbus --legacy` *to star Termux:11 without dbus and use _-legacy-drawing_ (nodbus and gpu)*
- `tx11start --legacy` *to star Termux:11 with _-legacy-drawing_ (with dbus and gpu)*
- `tx11start --debug --OTHER-PARAMETERS` *To see log of that commmand*
  >tx11start --debug --nogpu *To See tx11start --nogpu's log*

</details>

### Stop Termux:X11
```bash
tx11stop [-f]
```
Options:
- `-f`: Force stop.
- `--help`: To show help.

### Start VNC
```bash
vncstart [options]
```
Options:
- `--nogpu`: Disable GPU acceleration.
- `--help`: To show help.

### Stop VNC
```bash
vncstop [-f]
```
Options:
- `-f`: Force stop.
- `--help`: To show help.

### GUI Commands
```bash
gui [options]
```
Options:
- `--start`: Start GUI (use `vnc` or `tx11` as arguments).
- `--stop`: Stop GUI.
- `--kill`: Stop all GUI sessions.
- `--help`: To show help.

<details>
<summary>Full Example:</summary>

##### If you select only one of them to access gui
- `gui --start / gui -l` *to start Termux gui*
- `gui --stop / gui -s` *to stop gui*

##### If you select both for gui access
- `gui -l / --start` `vnc` *to start VNC*
- `gui -l / --start` `tx11` *to start Termux:X11*
- `gui -s / --stop` `vnc` *to stop VNC*
- `gui -s / --stop` `tx11` *to stop Termux:X11*
- `gui -k / --kill / -kill` *to kill both vncserver and Termux:x11 At Once*

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
- `--local-config` Start the installation from pre made config file
- `--help`: To show help.

<details>
<summary>Full Example:</summary>

- `setup-termux-desktop --change style` *To Change Desktop Style*
- `setup-termux-desktop --change hw` *To Change Hardware Acceleration Method*
- `setup-termux-desktop --change pd` *To Change Installed Proot-Distro*
- `setup-termux-desktop --change autostart` *To change autostart behaviour*
- `setup-termux-desktop --change display` *To change termux:x11 display port*
<br>

- `setup-termux-desktop --reinstall icons / themes /config` *To Reinstall Icons / Themes / Config*
- `setup-termux-desktop --reinstall icons,themes,..etc` *To Reinstall Them At Once*
<br>

- `setup-termux-desktop --reset` *To Reset All Changes Made By This Script Without Uninstalling The Packages*
<br>

- `setup-termux-desktop --remove / -r` *To Remove Termux Desktop*
<br>

- `setup-termux-desktop --local-config / -config` 	*Start the installation from pre made config file*
    > Each time you install the desktop environment or made some changes using the script it write all your config to the `/data/data/com.termux/files/usr/etc/termux-desktop/configuration.conf` file. Copy that somewhere else, so next time when you want to install the desktop environment with that old config all you have to do `setup-termux-desktop --local-config /path/to/configuration.conf`
<br>

- `setup-termux-desktop --debug` **(At The Start)** *To generate a log file for any of the above command*

  - `setup-termux-desktop --debug --install` *To create a log of whole installation process*

</details>

---

## Screenshots:

### Demo Looks

|XFCE|LXQT|
|--|--|
|![img](https://raw.githubusercontent.com/sabamdarif/termux-desktop/setup-files/images/xfce/look_1/desktop.png)|![img](https://raw.githubusercontent.com/sabamdarif/termux-desktop/setup-files/images/lxqt/look_2/start-menu.png)|
|**OPENBOX**|**MATE**|
|![img](https://raw.githubusercontent.com/sabamdarif/termux-desktop/setup-files/images/openbox/look_2/desktop.png)|![img](https://raw.githubusercontent.com/sabamdarif/termux-desktop/setup-files/images/mate/look_1/desktop.png)|

#### [See More...](https://github.com/sabamdarif/termux-desktop?tab=readme-ov-file#2-explore-desktop-styles)

### App Store:
<img src="https://raw.githubusercontent.com/sabamdarif/termux-desktop/setup-files/images/termux-app-store.png">

<details>
<summary><b>Appstore UI:</b></summary>

|Loading|Installing|
|--|--|
|![img](https://raw.githubusercontent.com/sabamdarif/termux-desktop/setup-files/images/appstore-loading.png)|![img](https://raw.githubusercontent.com/sabamdarif/termux-desktop/setup-files/images/appstore-app-installing.png)|
|Installed|Prompt|
|![img](https://raw.githubusercontent.com/sabamdarif/termux-desktop/setup-files/images/appstore-app-installed.png)|![img](https://raw.githubusercontent.com/sabamdarif/termux-desktop/setup-files/images/appstore-prmpt.png)|
</details>

---

## Advanced Topics:

### Wine:
Run Windows applications seamlessly. Learn more [here](https://github.com/sabamdarif/termux-desktop/blob/main/readmes/wine.md#wine_glasslearn-about-wine).

### Distro Containers:
Install additional apps like LibreOffice. Details [here](/readmes/proot-container.md).

### Hardware Acceleration:
Enhance performance with GPU acceleration. Learn more [here](/readmes/hw-acceleration.md).

---
## Associated Repos:

- [Termux-AppStore](https://github.com/sabamdarif/Termux-AppStore)  
  License: GPL
   
- [sabamdarif/nautilus-scripts](https://github.com/sabamdarif/nautilus-scripts/tree/termux)  
  License: MIT  
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

*Every contribution, no matter how small, helps keep this project alive and growing! ❤️*

---

Join the conversation: [Telegram Chat](https://t.me/hello_android_0).
