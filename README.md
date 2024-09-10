
<br>
<center><img src="images/xfce/look_1/desktop.png"></center>
<br>
<p align="center"><b style ="font-size: x-large">Easily Install Termux Gui Desktop </b></p>

<div align="center">

![GitHub stars](https://img.shields.io/github/stars/sabamdarif/termux-desktop)
![GitHub issues](https://img.shields.io/github/issues/sabamdarif/termux-desktop)

</div>

## Features:

- :books: Easy To Setup
- :desktop_computer: XFCE, LXQt, and Openbox, all supported
- :art: New Beautiful Theme And Styles
- :wine_glass: Wine To Run Windows Apps _(x86_64 in arm64 device)_
- :mechanical_arm: Hardware Acceleration Enabled
- :paperclips: Termux:X11 / Vnc For Gui Access
- :package: Work with both APT , PACMAN
-  :jigsaw: One Click To Install Some useful Apps
   - :globe_with_meridians: Browser: Firefox / Chromium
   - :man_technologist: Code Editor: VS Code / Geany
   - :camera: Image Editor: Gimp / Inkscape
- :package: Install apps like libreoffice _(apps that are not avilable in termux by default)_
- :link: And Much More...
<br>

## :warning: Follow This Steps :point_down:

### 1. Check Basic Requirment: [from here](#requirements)
### 2. Check All Avilable Desktop Styles:

<b>

- [XFCE](xfce_styles.md)
- [LXQT](lxqt_styles.md)
- [OPENBOX](openbox_styles.md)
>Openbox keybord shortcuts :- [Here](https://github.com/sabamdarif/termux-desktop/blob/main/see-more.md#openbox-keybindings-cheat-sheet)
</b>

### 3. Check About Hardware Acceleration : [from here](https://github.com/sabamdarif/termux-desktop?tab=readme-ov-file#hardware-acceleration-in-distro-container-and-also-in-termux)
### 4. Check About Distro Container: [from here](https://github.com/sabamdarif/termux-desktop?tab=readme-ov-file#want-to-install-more-apps-like-libreoffice-which-are-not-avilable-in-termux) [[Video Tutorial](https://youtu.be/KiUTyGZ2grE)]
### 5. Check Natively Supported Apps list: [from here](applist.md)
### 6. Installation: [from here](#installation) [[Video Tutorial](https://youtu.be/SlR9f9hl5CQ)]
### 7. Uses: [from here](#uses)
### 8. See More: [from here](see-more.md)

<a name="requirements"></a>

## Minimum Requirements:
- No Root Required
- Android 7+ phone
- [Termux](https://termux.dev/en/) From [Github](https://github.com/termux/termux-app/releases) Or [Fdroid](https://f-droid.org/en/packages/com.termux/)
> Termux from Google Play can't poperly install x11-packages due to API limitation, so instead use the F-Droid Or Github build.
- 2GB of RAM 3GB of RAM
- 1.5 - 2 GB Of Internet
- 3 - 4 GB Of Free Storage
- VNC Client [RealVnc](https://play.google.com/store/apps/details?id=com.realvnc.viewer.android) Or [Nethunter Kex](https://store.nethunter.com/en/packages/com.offsec.nethunter.kex/)
- [Termux:X11](https://github.com/termux/termux-x11/releases)
- [Termux-API](https://github.com/termux/termux-api/releases) _(For Openbox only)_

<br>

## Default Look (XFCE):

<center><img src="images/xfce/look_1/look.png"></center>
<br>

## See Other Styles: [XFCE](xfce_styles.md),[LXQT](lxqt_styles.md)

## Screenshots:
> All gui apps screenshot

### Browsers:

<center><img src="images/apps/firefox-chromium.png"></center>

### Image Editors:

<center><img src="images/apps/inkscape-gimp.png"></center>

### Code Editors:

<center><img src="images/apps/geany-vscode.png"></center>

### Media Players:

<center><img src="images/apps/parole-vlc.png"></center>

### Wine: [See More](https://github.com/sabamdarif/termux-desktop/blob/main/see-more.md#about-wine)

<center><img src="images/apps/wine.png"></center>

## See More Natively Supported Apps: [Here](applist.md)

## Want To Install More Apps (Like: Libreoffice) Which Are Not Avilable In Termux:

## See How To Use Distro Container: [Click Here](proot-caontainer.md)

## Libre Office:

<center><img src="images/apps/container-libreoffice-2.png"></center>

## Hardware Acceleration In Distro Container And Also In Termux:

<center><img src="images/pdrun-glmark2.png"></center>


## Know More About Hardware Acceleration: [Here](hw-acceleration.md)

<br>
<br>

<a name="installation"></a>

# Installation:

>NOTE: This Only Works On Termux From Github Or Fdroid

>NOTE: A Fresh Install Is Always Recommended


```bash
curl -Lf https://raw.githubusercontent.com/sabamdarif/termux-desktop/main/setup-termux-desktop -o setup-termux-desktop && chmod +x setup-termux-desktop && ./setup-termux-desktop
```

<a name="uses"></a>

## Uses:

### Command:- `tx11start`
- `tx11start` *to star Termux:11 with gpu acceleration*
- `tx11start --nogpu` *to star Termux:11 without gpu acceleration*
### Command:- `vncstart`
- `vncstart` *to start vncserver*
- `vncstart ---nogpu` *to start vncserver without gpu acceleration*
### Command:- `vncstop`
- `vncstop` *to stop vncserver*
- `vncstop -f` *to kill vncserver*

### Command:- `gui`
#### If you select only one of them to access gui
- `gui --start / gui -l` *to start Termux gui*
- `gui --stop / gui -s` *to stop gui*

#### If you select both for gui access
- `gui -l / --start` `vnc` *to start VNC*
- `gui -l / --start` `tx11` *to start Termux:X11*
- `gui -s / --stop` `vnc` *to stop VNC*
- `gui -s / --stop` `tx11` *to stop Termux:X11*
- `gui -k / --kill / -kill` *to kill both vncserver and Termux:x11 At Once*
<br>

### Command:- `setup-termux-desktop`
- `setup-termux-desktop --change style` *To Change Desktop Style*
- `setup-termux-desktop --change hw` *To Change Hardware Acceleration Method*
- `setup-termux-desktop --change pd` *To Change Installed Proot-Distro*
<br>

- `setup-termux-desktop --reinstall icons / themes /config` *To Reinstall Icons / Themes / Config*
- `setup-termux-desktop --reinstall icons,themes,..etc` *To Reinstall Them At Once*
<br>

- `setup-termux-desktop --reset` *To Reset All Changes Made By This Script Without Uninstalling The Packages*
<br>

- `setup-termux-desktop --remove / -r` *To Remove Termux Desktop*

## If you like my work then don't forget to give a Star :blush:
