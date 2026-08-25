## :mechanical_arm: Hardware Acceleration in Termux

> [!IMPORTANT]
> One thing to note: hardware acceleration in Termux is still experimental, so it may or may not work on your device.

### When setting up hardware acceleration in Termux, follow these steps for optimal configuration:

#### Select your device GPU

- During the Installation the script will first try to auto detect your gpu and if it failed then it will ask you to chose your device gpu

> [!TIP]
>
> ##### If you don't know what gpu you have , then follow this:-
>
> Use [CPU-Z](https://play.google.com/store/apps/details?id=com.cpuid.cpu_z&pcampaignid=web_share) to identify your GPU.

- Like in my case i can see i have a Mali GPU
  ![CPU-Z Screenshot](https://raw.githubusercontent.com/sabamdarif/termux-desktop/setup-files/images/cpu-z.png)

#### Select Driver

The script asks three questions, in this order.

##### 1. Which Vulkan driver do you want?

> Vulkan is the modern and the best Api for Linux, but compared to OpenGL it's new so not every app supports it yet. Using something like Zink you can get OpenGL on top of it, though that depends on your device.

| Option                                         | What it is                                                        | Good for                                             |
| ---------------------------------------------- | ----------------------------------------------------------------- | ---------------------------------------------------- |
| Android Vulkan Wrapper                         | Wraps the Vulkan driver that already ships in your Android system | Most devices, try this one first                     |
| Android Vulkan Wrapper (pipetto-crypto's fork) | Same idea, different fork                                         | Mali, when the first one didn't work well            |
| Turnip                                         | Mesa's native Adreno Vulkan driver                                | Adreno, it needs Zink or VirGL for OpenGL            |
| Turnip + Fryzek's KGSL                         | Native Adreno Vulkan **and** native Adreno OpenGL in one package  | Adreno, best option, and no OpenGL question after it |
| Skip                                           | No Vulkan driver at all                                           | When you only want OpenGL through VirGL              |

> [!NOTE]
> `Turnip + Fryzek's KGSL` is two drivers in one package. Turnip is Mesa's Adreno Vulkan driver. The KGSL part is the KGSL backend for Mesa's gallium (OpenGL) freedreno driver from [this merge request](https://gitlab.freedesktop.org/mesa/mesa/-/merge_requests/21570) by Lucas Fryzek, which was never merged upstream and is kept alive by the community (xMeM ported it to Termux:X11, Robert Kirkman integrated and improved it). Because it carries a native OpenGL driver, it's the only option that needs neither Zink nor VirGL.

##### 2. How should OpenGL work?

This gets asked for every option except `Turnip + Fryzek's KGSL`, which already gives you OpenGL.

- `Zink` translates OpenGL to Vulkan using the driver you picked in step 1. Try this one first.
- `Zink (Legacy Mesa 22 Build)` is the older `mesa-zink` build, worth a try when the modern one shows glitches.
- The `VirGL` options pass OpenGL through to Android instead. They don't use your Vulkan driver at all, and they are the way out when Zink doesn't work on your device, which happens on a lot of devices with the wrapper drivers. That's why they are still here instead of falling back to llvmpipe.
- `Skip` installs no OpenGL driver. Only OpenGL falls back to Mesa's software renderer (llvmpipe), Vulkan apps keep using the driver you picked in step 1. Pick this when you only care about Vulkan and don't want a translation layer in the way. It isn't offered when you also skipped Vulkan, because that would leave nothing accelerated at all, use `enable_hw_acc=n` for that.

> [!NOTE]
> `Skip` is not the same as `--nogpu`. They use the same software renderer for OpenGL, but `--nogpu` turns off Vulkan too, while `Skip` keeps your Vulkan driver working.

> [!IMPORTANT]
> None of the VirGL options give apps Vulkan, they only give OpenGL. Venus, the Vulkan passthrough part of virglrenderer, needs a virtio-gpu device that doesn't exist on Android. `VirGL + ANGLE Vulkan Backend` does use Vulkan, but only inside ANGLE to produce OpenGL. App facing Vulkan always comes from step 1.

##### 3. Hardware acceleration for the distro container

This one only gets asked when it isn't already decided by your earlier answers:

- Picked `Turnip` in step 1, so the distro uses Turnip.
- Picked `Turnip + Fryzek's KGSL`, so the distro uses the same thing.
- Don't have an Adreno GPU, so the distro uses VirGL. The distro's Vulkan loader can't load an Android wrapper driver from inside the container, so there is nothing to choose.
- Have an Adreno GPU but picked a wrapper driver (or `Skip`), so you get asked, because the native drivers are still an option inside the distro.

The distro side driver is one build that carries Turnip and Fryzek's KGSL together. It installs under `/opt/mesa-freedreno` so the distro's own Mesa stays untouched, which is what keeps `pdrun --nogpu` working and makes removing it a single `rm -rf /opt/mesa-freedreno`.

Once selected, everything will be configured automatically.

### Using Hardware Acceleration in Termux

- Start Termux Desktop via Termux:X11 (recommended) or VNC (In VNC, some drivers might not work)
- And it should just work if the selected driver supports your GPU.

### Using Hardware Acceleration in Proot Distro (Distro Container)

#### Method 1: Terminal Commands (pdrun)

> Remember, you should always run pdrun from Termux's shell; never run it from inside a proot-distro.

1.  Launch Termux Desktop.
2.  Run programs in Termux terminal:

        ```bash
        pdrun program
        ```

        - By default pdrun runs programs with GPU acceleration.
        - To run program without GPU acceleration, Use:-

        ```bash
        pdrun --nogpu program
        ```

    ![GLMark2 Results](https://raw.githubusercontent.com/sabamdarif/termux-desktop/setup-files/images/pdrun-glmark2.png)

### Method 2: Termux Menu

1. Add the desired program to the Termux menu.
2. Launch the program directly from the Termux menu.

> [!NOTE]
> To know more on how to add a program from proot-distro to Termux, check this: [HERE](/docs/proot-container.md#adding-apps-to-the-termux-desktop-app-menu)

## Changing Hardware Acceleration Drivers

### Manual Configuration

1. **Install required packages:**
   `pkg install mesa virglrenderer vulkan-loader-generic angle-android virglrenderer-android`
2. Navigate to `$PREFIX/bin` and edit the following files using `nano` or `vim`:
    - `vncstart`
    - `tx11start`
    - `pdrun`
3. Look for the line at the bottom of tx11start, you will find lines similar to these:

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

- You need to change the `export`, `virgl_test_server --use-egl-surfaceless --use-gles &`, and the `GALLIUM_DRIVER=virpipe` values.

- **How to get these values:**
- [See this function](/enable-hw-acceleration#L218)
- Here, the value under `set_to_export=` replaces the word after `export` in the tx11start file
- Here, the value under `gpu_environment_variable=` replaces the `VK_ICD_FILENAMES=... vblank_mode=0` part
- Here, the value under `initialize_server_method=` replaces the `virgl_test_server --use-egl-surfaceless --use-gles &`

- Then save and exit

- **For file `pdrun`:**
- At the top, there will be `selected_pd_hw_method="GALLIUM_DRIVER=virpipe MESA_GL_VERSION_OVERRIDE=4.0"`
- Change the `GALLIUM_DRIVER=virpipe MESA_GL_VERSION_OVERRIDE=4.0` with the value under `pd_hw_method=`
- For the native Adreno drivers those values point inside `/opt/mesa-freedreno`, and `MESA_LOADER_DRIVER_OVERRIDE` is what picks between them: `zink` for Turnip, `kgsl` for Fryzek's KGSL
- Then save and exit

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
