
<br>
<center><img src="images/xfce/1_look/desktop.png"></center>
<br>
<p align="center"><b>Easily Install Termux Gui Desktop </b></p>
<p align="center"><b>With Some Popular Gui Apps Directly In Termux</b></p>

<div align="center">

![GitHub stars](https://img.shields.io/github/stars/sabamdarif/termux-gui)
![GitHub issues](https://img.shields.io/github/issues/sabamdarif/termux-gui)

</div>

## Features:

- :globe_with_meridians: 2 Browsers ( Chromium & Mozilla Firefox )
- :tv: VLC Media Player work fine
- :books: Easy To Setup
- :man_technologist: Two Code Editor ( VS Code & Geany )
- :camera: Two Image Editor ( Gimp & Inkscape )
- :wine_glass: Wine To Run Windows Apps ( [arm64 supported only](https://armrepo.ver.lt/) )
- :art: New Sets of Beautiful Theme And Wallpapers
- :paperclips: Termux:X11 Added
- :link: And Much More...

## Requirements:
- No root permission is required to make this work
- An Android 7+ phone
- [Termux](https://termux.dev/en/) From [Github](https://github.com/termux/termux-app/releases) Or [Fdroid](https://f-droid.org/en/packages/com.termux/)
> Termux from Google Play is unmaintained due to API requirements So use the F-Droid one instead.
- 1GB of RAM (minimum) 2GB of RAM (recommended)
- VNC Client [RealVnc](https://play.google.com/store/apps/details?id=com.realvnc.viewer.android) Or [Nethunter Kex](https://store.nethunter.com/en/packages/com.offsec.nethunter.kex/)

## Basic Look:

<center><img src="images/xfce/1_look/look.png"></center>

## See All Styles: [Here](xfce_styles.md)

## Screenshots:
> All gui apps screenshot

### Browsers:

<center><img src="images/firefox-chromium.png"></center>

### Image Editors:

<center><img src="images/inkscape-gimp.png"></center>

### Code Editors:

<center><img src="images/geany-vscode.png"></center>

### Media Players:

<center><img src="images/parole-vlc.png"></center>

### Wine:

<center><img src="images/wine.png"></center>

## See More Available Apps: [Here](applist.md)

<br>
<br>

## Installation:

>NOTE: This only works on Termux
>NOTE: Install wget in termux first

```
pkg install wget -y
```

```
wget https://raw.githubusercontent.com/sabamdarif/termux-gui/main/setup-termux-gui.sh && bash setup-termux-gui.sh
```
## Usage:
- **Type `vncstart` OR `gui -start` to start vnc server.**
- **Type `vncstop` OR `gui -stop` to start vnc server.**
- **Type `gui -tx11` to star using Termux:11.**
- **Type `vncstop -f` to kill vncserver OR `gui -kill` to kill both.**

## If you like my work then dont forget to give a Star :)