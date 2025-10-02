## :mechanical_arm: Hardware Acceleration in Termux

> [!IMPORTANT]
> One thing to note: hardware acceleration in Termux is still experimental, so it may or may not work on your device.

### When setting up hardware acceleration in Termux, follow these steps for optimal configuration:

### Installation

- Run the Installer Script and choose your preferred hardware acceleration method during the installation.
- If you opt for a distro container, select the hardware acceleration method for the distro as well.
  > For Adreno GPU you don't nedd to chose, it will automatically use turnip if you use ubuntu/debian
- Once selected, everything will be configured automatically.

> [!TIP]
> Use [CPU-Z](https://play.google.com/store/apps/details?id=com.cpuid.cpu_z&pcampaignid=web_share) to identify your GPU. Research your GPU online to determine whether `virpipe` or `zink` or `icd-wrapper`... works best; Reddit or similar forums often have useful insights.  
> Although for most of the gpu icd-wrapper (vulkan) should work just fine

![CPU-Z Screenshot](https://raw.githubusercontent.com/sabamdarif/termux-desktop/setup-files/images/cpu-z.png)

### Using Hardware Acceleration in Termux

- Start Termux Desktop via Termux:x11 (recommended) or vnc (In vnc some drivers might not work)
- And it should just work if the hardware acceleration driver you selected that support your gpu.

### Using Hardware Acceleration in Proot Distro (Distro Container)

#### Method 1: Terminal Commands (pdrun)

> Remember you should always run pdrun from termux's shell, never run it from inside a proot-distro

1. Launch Termux Desktop.
2. Run programs in Termux terminal:
   ```bash
   pdrun program
   ```

   - By default pdrun runs programs with GPU acceleration.
   ```bash
   pdrun --nogpu program
   ```

   - To run program without GPU acceleration.

![GLMark2 Results](https://raw.githubusercontent.com/sabamdarif/termux-desktop/setup-files/images/pdrun-glmark2.png)

### Method 2: Termux Menu

1. Add the desired program to the Termux menu.
2. Launch the program directly from the Termux menu.

> [!NOTE]
> To know more no how to add a program from proot-distro to termux, check this:- [HERE](/docs/proot-container.md#adding-apps-to-the-termux-desktop-app-menu)

## Changing Hardware Acceleration Drivers

### Manual Configuration

1. **Install Required Packages.**
   `pkg install mesa virglrenderer vulkan-loader-generic angle-android virglrenderer-android`
2. Navigate to `$PREFIX/bin` and edit the following files using `nano` or `vim`:
   - `vncstart`
   - `tx11start`
   - `pdrun`
3. Look for the line at the bottom of tx11start:
   there will be some lines like this

   ```bash
   export MESA_NO_ERROR=1 MESA_GL_VERSION_OVERRIDE=4.1COMPAT MESA_GLES_VERSION_OVERRIDE=3.2 MESA_GLSL_VERSION_OVERRIDE=410 LIBGL_DRI3_DISABLE=1 EPOXY_USE_ANGLE=1 LD_LIBRARY_PATH=/data/data/com.termux/files/usr/opt/angle-android/vulkan
   virgl_test_server --use-egl-surfaceless --use-gles &
   sleep 1
   XDG_RUNTIME_DIR=${TMPDIR} termux-x11 :0 &
   sleep 1
   am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity > /dev/null 2>&1 &
   sleep 1
   env DISPLAY=:0 XDG_CONFIG_DIRS=/data/data/com.termux/files/usr/etc/xdg VK_ICD_FILENAMES=/data/data/com.termux/files/usr/share/vulkan/icd.d/wrapper_icd.aarch64.json MESA_VK_WSI_PRESENT_MODE=mailbox MESA_VK_WSI_DEBUG=blit MESA_SHADER_CACHE=512MB MESA_SHADER_CACHE_DISABLE=false vblank_mode=0 GALLIUM_DRIVER=virpipe dbus-launch --exit-with-session xfce4-session > /dev/null 2>&1 &
   ```

- you need to change the `export` , `virgl_test_server --use-egl-surfaceless --use-gles &` and the `GALLIUM_DRIVER=virpipe` value

- **How you will get this values:-**
- [See this function](/enable-hw-acceleration#L96)
- here the value under `set_to_export=` will replace the word after `export` in the tx11start file
- here the value under `hw_method=` will replace the `GALLIUM_DRIVER=virpipe` text
- here the value under `initialize_server_method=` will replace the `virgl_test_server --use-egl-surfaceless --use-gles &`

- then save and exit

- **For file `pdrun` :-**
- at the top there will be `selected_pd_hw_method="GALLIUM_DRIVER=virpipe MESA_GL_VERSION_OVERRIDE=4.0"`
- change the `GALLIUM_DRIVER=virpipe MESA_GL_VERSION_OVERRIDE=4.0` with the value under `hw_method=`
- then save and exit

### Automatic Configuration

Run the following command to change drivers:

```bash
setup-termux-desktop --change hw
```

---

# :chart_with_upwards_trend: Performance Results

## Experimental Driver Performance

### Adreno with `mesa-vulkan-icd-wrapper` and Turnip

![Adreno Experimental Performance](https://raw.githubusercontent.com/sabamdarif/termux-desktop/setup-files/images/exp-hwa-adreno.png)

### Mali with `mesa-vulkan-icd-wrapper`

![Mali Experimental Performance](https://raw.githubusercontent.com/sabamdarif/termux-desktop/setup-files/images/exp-hwa-mali.png)

### Test Environment

> These tests and results were conducted by [LinuxDroidMaster](https://github.com/LinuxDroidMaster).

- **Device:** Lenovo Legion Y700 (Snapdragon 870, Adreno 650)
- **Distro:** Debian in Proot with XFCE4 Desktop
- **GLMark2**: Used to evaluate GPU performance.

### GLMark2 Scores: Proot Distro

| Run | LLVMPIPE | VIRGL | VIRGL ZINK | TURNIP | ZINK  |
| --- | -------- | ----- | ---------- | ------ | ----- |
| 1   | 93       | 70    | 66         | 198    | Error |
| 2   | 93       | 77    | 66         | 198    | Error |
| 3   | 72       | 70    | 71         | 198    | Error |
| 4   | 94       | 76    | 66         | 197    | Error |
| 5   | 93       | 75    | 67         | 198    | Error |

#### Commands Used:

| Driver     | Command                                                       |
| ---------- | ------------------------------------------------------------- |
| LLVMPIPE   | `glmark2`                                                     |
| VIRGL      | `GALLIUM_DRIVER=virpipe MESA_GL_VERSION_OVERRIDE=4.0 glmark2` |
| VIRGL ZINK | `GALLIUM_DRIVER=virpipe MESA_GL_VERSION_OVERRIDE=4.0 glmark2` |
| TURNIP     | `MESA_LOADER_DRIVER_OVERRIDE=zink TU_DEBUG=noconform glmark2` |
| ZINK       | `GALLIUM_DRIVER=zink MESA_GL_VERSION_OVERRIDE=4.0 glmark2`    |

---

### GLMark2 Scores: Termux (No Proot)

| Run | LLVMPIPE | VIRGL | VIRGL ZINK | ZINK | TURNIP |
| --- | -------- | ----- | ---------- | ---- | ------ |
| 1   | 69       | Error | 92         | 121  | N/A    |
| 2   | 70       | Error | 92         | 122  | N/A    |
| 3   | 69       | Error | 93         | 121  | N/A    |
| 4   | 69       | Error | 93         | 124  | N/A    |
| 5   | 69       | Error | 93         | 123  | N/A    |

---

### Firefox Aquarium WebGL Benchmark

#### Proot Distro Results (Firefox-ESR WebGL Aquarium FPS)

| LLVMPIPE | VIRGL | VIRGL ZINK | TURNIP         |
| -------- | ----- | ---------- | -------------- |
| 4        | 20    | 17         | Web page crash |

#### Termux Results (Firefox-ESR WebGL Aquarium FPS)

| LLVMPIPE | VIRGL | VIRGL ZINK | ZINK | TURNIP |
| -------- | ----- | ---------- | ---- | ------ |
| 2        | Error | 24         | 40   | N/A    |

![WebGL Aquarium on Firefox](https://raw.githubusercontent.com/sabamdarif/termux-desktop/setup-files/images/webglaquarium.png)

---

### Additional Testing

- **SuperTuxKart:** Benchmarked over 30 seconds.

![SuperTuxKart Comparison](https://raw.githubusercontent.com/sabamdarif/termux-desktop/setup-files/images/supertuxkart_comparison.png)
