## :hammer_and_wrench:Learn about terminal utilities:

### 1.Extra Installed Packages
- **[nala](https://github.com/volitank/nala):** Nala is a front-end  for apt
- **[bat](https://github.com/sharkdp/bat):** Better replacement of cat
- **[eza](https://github.com/eza-community/eza):** A modern, maintained replacement for ls
- **[fastfetch](https://github.com/fastfetch-cli/fastfetch):** Better replacement of neofetch
- **[zoxide](https://github.com/ajeetdsouza/zoxide):** A smarter cd command

#### How to use them ?
- ***cd*** is replaced with ***zoxide*** (*use the cd command as normal it will use zoxide to change directories*)
- use ***pkg*** or ***apt*** command it will automatically use ***nala*** to install packages
- use ***ls*** command it will use ***eza*** for that
- use ***neofetch*** command it will use ***fastfetch*** for that
- use ***cat*** command it will use ***bat*** fot that
#### 2.Special Functions

- **extract:** Use extract command to extract any archive
- **ftext:** Searches for text in all files in the current folder
- **cpp:** Copy file with a progress bar
- **cpg:** Copy and go to the directory
- **mvg:** Move and go to the directory
- **mkdirg:** Create and go to the directory

## About Wine:

### There is three wine intallation option

 - **Native:-** it can run apps based on your cpu architecture, like in arm based cpu you can only install windows [arm apps](https://armrepo.ver.lt/)
 - **Mobox:-** it can run X86_64 windows apps in aarch64 device
 - **Hangover-wine:-** (can only be install using [pacman package manager](https://wiki.termux.com/wiki/Switching_package_manager)), do the same thing like mobox
