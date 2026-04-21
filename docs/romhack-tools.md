## :joystick: Pokémon GBA/NDS Romhack Development Tools

This optional step sets up a complete development environment for creating custom Pokémon ROM hacks for **GBA** (Game Boy Advance) and **NDS** (Nintendo DS) platforms, using **code-oss** as the editor.

---

### What Gets Installed

#### In Termux (always, when the option is enabled)

| Tool | Purpose |
| --- | --- |
| `make` | Build automation for decomp projects |
| `nasm` | x86/ARM assembler |
| `clang` | C/C++ compiler for native host tools |
| `perl` | Symbol file generation and decomp scripting |
| `xdelta3` | Create and apply binary ROM patches |
| `python` | Required by decomp build systems |
| `Pillow` _(pip)_ | Image processing for ROM graphics/sprites |
| `PyYAML` _(pip)_ | YAML parsing used by decomp build configs |
| `ndspy` _(pip)_ | Read and write NDS ROM files from Python |
| `colorama` _(pip)_ | Colored terminal output used by decomp Python tooling |

#### In the Linux Container (Debian / Ubuntu / Arch — when a distro is configured)

| Tool | Purpose |
| --- | --- |
| `arm-none-eabi-gcc` | ARM cross-compiler for GBA/NDS target code |
| `gba-dev` | devkitPro GBA libraries and tools (libgba, grit, etc.) |
| `nds-dev` | devkitPro NDS libraries and tools (libnds, ndstool, etc.) |
| `build-essential` / `base-devel` | Native host C/C++ compiler for building decomp host tools |
| `libpng-dev` / `libpng` | Required by gbagfx and other decomp tool compilations |

> **Why the container?** Termux does not provide an ARM cross-compiler in its own package repos. The [devkitPro](https://devkitpro.org) toolchain is installed inside the proot/chroot Linux container, which has access to the official devkitPro package repos.

> **Fedora containers:** Automated devkitPro installation is not supported. Follow the manual guide at https://devkitpro.org/wiki/Getting_Started.

---

### Desktop Menu Shortcut

When a Linux container is configured and the toolchain is installed successfully, a **"devkitPro Shell"** entry is automatically added to the Termux desktop application menu.

Clicking it opens your container's terminal shell with the devkitPro environment already loaded — `arm-none-eabi-gcc`, `make`, `grit`, `ndstool` and all other toolchain binaries are immediately available without any manual setup.

You can also open it from the terminal at any time:

```bash
# Replace 'debian' with your configured distro name
debian
```

---

### Development Workflow

```
Android device
│
├── code-oss (Termux desktop)
│     Write and edit your decomp project files
│     Project lives in your Termux $HOME
│
└── devkitPro Shell (Linux container)
      Run `make` to compile
      arm-none-eabi-gcc and full devkitPro toolchain available
      Reads/writes the same project files via shared $HOME
```

1. **Edit** source files in code-oss as you would on any desktop Linux
2. **Open "devkitPro Shell"** from the desktop menu (or type your distro name in a terminal)
3. Navigate to your project and **run `make`**
4. The compiled `.gba` / `.nds` ROM is written to your project folder
5. **Test** with an Android emulator app ([My Boy!](https://play.google.com/store/apps/details?id=com.fastemulator.gba) for GBA, [melonDS](https://play.google.com/store/apps/details?id=me.magnum.melonds) for NDS) — they access the same storage

---

### Enabling the Option

When running the setup script, answer **`y`** when prompted:

```
Do you want to install Pokémon GBA/NDS romhack development tools (y/n)
```

To enable it via a pre-made config file, add the following line:

```
romhack_tools_answer=y
```

The default in the generic config is `n` (opt-in).

---

### Resources

- [devkitPro Getting Started](https://devkitpro.org/wiki/Getting_Started)
- [pokeemerald decomp (GBA)](https://github.com/pret/pokeemerald)
- [pokeheartgold decomp (NDS)](https://github.com/pret/pokeheartgold)
- [ndspy documentation](https://ndspy.readthedocs.io)
- [xdelta3 usage](http://xdelta.org)
