## Expanding Termux Functionality with Distro Containers

#### Video Guide: [YouTube](https://youtu.be/KiUTyGZ2grE?si=9L8pg00Vf--64Tsp)

Termux natively supports a limited selection of applications. However, with this script, you can extend Termux's capabilities by integrating applications from other Linux distributions using a **Distro Container**. The best part? There’s no need to log in to the Proot/chroot-distro to access these apps; they seamlessly integrate into Termux, appearing in its desktop app menu and launching directly from the Termux terminal.

---

### Key Features

- **Expand Termux’s App Ecosystem**: Install additional applications from various Linux distributions into Termux.
- **Integrated Access**: Run installed apps directly in Termux without needing to log in to the Proot distro.
- **Desktop Menu Integration**: Applications can be added to the Termux desktop app menu for easy access.

---

### How to Use the Script

#### NOTE: For chroot-distro, flash this module first: [sabamdarif/chroot-distro](https://github.com/sabamdarif/chroot-distro)

1. **Run the Installer Script**:
    - When prompted about setting up a Distro Container, type `y` to continue.

2. **Select a Distribution**:
    - Choose a distribution from the list provided by typing the corresponding number. The script will handle the installation and configuration.

3. **Set Up a User Account**:
    - It is recommended to create a user account during setup. Once complete, you’re ready to use the container.

---

### Running Installed Apps in Termux

If you’ve installed an app in your distro (e.g., Debian) and want to run it directly from Termux, use the following command:

```bash
pdrun <package-name>
```

**Example**: To run LibreOffice, type:

```bash
pdrun libreoffice
```

<center><img src="https://raw.githubusercontent.com/sabamdarif/termux-desktop/setup-files/images/apps/container-pdrun-libreoffice.png"></center>

---

### Adding Apps to the Termux Desktop App Menu

You can add installed applications to the Termux desktop menu for quick access in two ways:

1. **Using the Terminal Command**:
    - Type `add2menu` in the terminal, and select the app you want to add.

2. **Using the “Add to Menu” App**:
    - Open the `Add to Menu` app from Termux, and choose the application you want to add.

Once added, the app will appear in the Termux desktop menu.

<center><img src="https://raw.githubusercontent.com/sabamdarif/termux-desktop/setup-files/images/add2menu-icon.png"></center>
<center><img src="https://raw.githubusercontent.com/sabamdarif/termux-desktop/setup-files/images/add2menu-option.png"></center>
<center><img src="https://raw.githubusercontent.com/sabamdarif/termux-desktop/setup-files/images/add2menu-main-window.png"></center>
<center><img src="https://raw.githubusercontent.com/sabamdarif/termux-desktop/setup-files/images/pd-appps.png"></center>

---

### Installing and Adding Apps in One Step

For a faster setup, use the following command to install an app and add it to the Termux menu simultaneously:

```bash
<Distro-Name> install <package-name>
```

**Example**: To install and add LibreOffice in Debian, type:

```bash
debian install libreoffice
```

<center><img src="https://raw.githubusercontent.com/sabamdarif/termux-desktop/setup-files/images/apps/container-libreoffice-2.png"></center>

If this method doesn’t work for any reason, you can manually add the app to the menu using the steps outlined above.

---

### Logging into the Installed Distro

- **Log in as a Regular User**:
    - Type the name of the installed distribution, e.g., `debian`, to log in.

- **Log in as Root**:
    - Use the `--root` or `-r` flag to log in as root:

    ```bash
    debian --root
    ```

- **Remove the Distro**:
    - To uninstall the distribution and remove all related files, use:

    ```bash
    debian --remove
    ```

- **Show Help**:
    - Display help information for the distribution with:

    ```bash
    debian --help
    ```
