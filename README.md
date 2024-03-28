
<br>
<center><img src="images/xfce/1_look/desktop.png"></center>
<br>
<p align="center"><b>Easily Install Termux Gui Desktop </b></p>
<p align="center"><b>With Some Popular Gui Apps Directly In Termux</b></p>

<div align="center">

![GitHub stars](https://img.shields.io/github/stars/sabamdarif/termux-desktop)
![GitHub issues](https://img.shields.io/github/issues/sabamdarif/termux-desktop)

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
- 1.5 - 2 GB Of Internet
- VNC Client [RealVnc](https://play.google.com/store/apps/details?id=com.realvnc.viewer.android) Or [Nethunter Kex](https://store.nethunter.com/en/packages/com.offsec.nethunter.kex/)

<br>

## Basic Look:

<center><img src="images/xfce/1_look/look.png"></center>
<br>

# See Other Styles: [Here](xfce_styles.md)

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

### Wine:

<center><img src="images/apps/wine.png"></center>

## See More Available Apps: [Here](applist.md)

<br>
<br>

## Installation:

>NOTE: This only works on Termux

>NOTE: A Fresh Desktop Install Is Always Best / Recommended

### Steps:

```
pkg update -y
```
```
pkg install wget -y
```
```
wget https://raw.githubusercontent.com/sabamdarif/termux-desktop/main/setup-termux-desktop
```
```
chmod +x setup-termux-desktop
```
```
./setup-termux-desktop
```
### One Line Install:

```
pkg update -y ; pkg install wget -y ; wget https://raw.githubusercontent.com/sabamdarif/termux-desktop/main/setup-termux-desktop ; chmod +x setup-termux-desktop ; ./setup-termux-desktop
```


## Usage:
- **Type `vncstart` OR `gui -start` to start vnc server.**
- **Type `vncstop` OR `gui -stop` to start vnc server.**
- **Type `gui -tx11` to star using Termux:11.**
- **Type `vncstop -f` to kill vncserver**
- **Type `gui -kill` to kill both vncserver and Termux:x11 At Once**
## If you like my work then dont forget to give a Star :)
