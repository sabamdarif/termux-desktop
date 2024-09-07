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
---
## :wine_glass:Learn about Wine:

#### There is three type of wine intallation options

 - **Native:-** it can run apps based on your cpu architecture, like in arm based cpu you can only install windows [arm apps](https://armrepo.ver.lt/)
 - **Mobox:-** it can run x86_64 windows apps in aarch64 device with good performance
 > **:warning: You need to set up Mobox after the termux-desktop installation finishes [From Here](https://github.com/olegos2/mobox)**
 - **Hangover-wine:-** (can only be install using [pacman package manager](https://wiki.termux.com/wiki/Switching_package_manager)), do the same thing like mobox
