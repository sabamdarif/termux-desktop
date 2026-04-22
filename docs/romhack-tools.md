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
| `Porymap` _(pre-built ARM64 binary)_ | Visual map and tileset editor for Gen 3 decomp projects. Downloaded automatically during setup — no compilation required |
| `Poryscript` _(pre-built ARM64 binary)_ | High-level scripting language compiled to native Gen 3 scripts. Used by most active pokeemerald projects. Invoked automatically by `make` |

> **Why the container?** Termux does not provide an ARM cross-compiler in its own package repos. The [devkitPro](https://devkitpro.org) toolchain is installed inside the proot/chroot Linux container, which has access to the official devkitPro package repos.

> **Fedora containers:** Automated devkitPro installation is not supported. Follow the manual guide at https://devkitpro.org/wiki/Getting_Started.

---

### Desktop Menu Shortcut

When a Linux container is configured and the toolchain is installed successfully, two entries are automatically added to the Termux desktop application menu:

- **devkitPro Shell** — opens your container's terminal with the full ARM toolchain on `$PATH`. Use this to run `make` and compile your ROM.
- **Porymap** — launches the Porymap map/tileset editor directly as a graphical window. Requires the X11 display server to be running (start it with `tx11start` or the Termux:x11 app).

You can also open either tool from the terminal at any time:

```bash
# Replace 'debian' with your configured distro name
debian --devkitpro  # open devkitPro Shell
pdrun porymap       # launch Porymap
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
2. **Open "Porymap"** from the desktop menu to edit maps and tilesets visually
3. Write event scripts as `.pory` files — **Poryscript** compiles them automatically during `make`
4. **Open "devkitPro Shell"** from the desktop menu (or type your distro name in a terminal)
5. Navigate to your project and **run `make`**
6. The compiled `.gba` / `.nds` ROM is written to your project folder
7. **Test** with an Android emulator app ([My Boy!](https://play.google.com/store/apps/details?id=com.fastemulator.gba) for GBA, [melonDS](https://play.google.com/store/apps/details?id=me.magnum.melonds) for NDS) — they access the same storage

---

### Enabling the Option

When running the setup script, answer **`y`** when prompted:

```
Do you want to install Pokémon GBA/NDS romhack development tools (y/n)
```

Porymap is installed automatically as part of this step — no separate prompt is shown.

To enable via a pre-made config file:

```
romhack_tools_answer=y
```

The default in the generic config is `n` (opt-in).

---

### Resources

- [devkitPro Getting Started](https://devkitpro.org/wiki/Getting_Started)
- [Porymap documentation](https://huderlem.github.io/porymap/)
- [Poryscript documentation](https://github.com/huderlem/poryscript#readme)
- [pokeemerald decomp (GBA)](https://github.com/pret/pokeemerald)
- [pokeheartgold decomp (NDS)](https://github.com/pret/pokeheartgold)
- [ndspy documentation](https://ndspy.readthedocs.io)
- [xdelta3 usage](http://xdelta.org)
