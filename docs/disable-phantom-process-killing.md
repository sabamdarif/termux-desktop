## Commands to disable phantom process killing

### Commands for Android 14 and higher

**Enable toggle once** at `Android Settings` -> `System` -> `Developer options` -> `Disable child process restrictions` to disable killing of **extra phantom processes `> 32`** and **processes using excessive cpu**. You will need to enable `Developer options` first on your device for it to show in `System` settings page, and it can usually be done by tapping `Android Settings` -> `About` -> `Build number` field `7` times.

- `root`: `su -c "setprop persist.sys.fflag.override.settings_enable_monitor_phantom_procs false"`

- **If you disable `Developer options` again, then `Disable child process restrictions` toggle will be disabled again automatically and killing of phantom processes will be enabled again.** To enabled at all times and can setup `adb`/`root`, then follow the instructions in [Commands for Android 12L, 13 and higher](#commands-for-android-12l-13-and-higher) section instead.

### Commands for Android 12L, 13 and higher

**Run commands once** to disable killing of **extra phantom processes `> 32`** and **processes using excessive cpu**.

- `root`: `su -c "settings put global settings_enable_monitor_phantom_procs false"`
- `adb`: `adb shell "settings put global settings_enable_monitor_phantom_procs false"`
- `root`: `su -c "setprop persist.sys.fflag.override.settings_enable_monitor_phantom_procs false"` (Not recommended as it will revert to its default value `true` if `Developer options` are disabled on Android `>= 14`)

### Commands for Android 12

Just set `max_phantom_processes` to `2147483647` to permanently disable killing of **extra phantom processes `> 32`**.

- `root`: `su -c "/system/bin/device_config put activity_manager max_phantom_processes 2147483647"`
- `adb`: `adb shell "/system/bin/device_config put activity_manager max_phantom_processes 2147483647"`

## Acknowledgments:

- This blog is taken from [agnostic-apollo/Android-Docs](https://github.com/agnostic-apollo/Android-Docs)

## To know more [read this](https://github.com/agnostic-apollo/Android-Docs/blob/master/en/docs/apps/processes/phantom-cached-and-empty-processes.md#how-to-disable-the-phantom-processes-killing)
