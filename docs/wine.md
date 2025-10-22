## :hammer_and_wrench:How compile box64 (termux native):

```bash
pkg install glibc-repo glibc-runner -y
```

```bash
pkg install git cmake-glibc make-glibc python-glibc libandroid-spawn libandroid-sysv-semaphore -y
```

```bash
pkg install git cmake-glibc make-glibc python-glibc libandroid-spawn libandroid-sysv-semaphore -y
```

```bash
unset LD_PRELOAD; export GLIBC_PREFIX=/data/data/com.termux/files/usr/glibc
```

```bash
export PATH=$GLIBC_PREFIX/bin:$PATH
```

```bash
cd ~/; git clone https://github.com/ptitSeb/box64; cd ~/box64
```

```bash
sed -i 's/\/usr/\/data\/data\/com.termux\/files\/usr\/glibc/g' CMakeLists.txt
```

```bash
sed -i 's/\/etc/\/data\/data\/com.termux\/files\/usr\/glibc\/etc/g' CMakeLists.txt
```

```bash
mkdir build; cd build
```

```bash
cmake --install-prefix $PREFIX/glibc .. -DARM_DYNAREC=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBAD_SIGNAL=ON -DSD845=ON
```

```bash
make -j8
```

```bash
make install
```

## :wine_glass:Learn about Wine:

<center><img src="https://raw.githubusercontent.com/sabamdarif/termux-desktop/setup-files/images/apps/wine.png"></center>

#### Using XoW64-wine

- **Xow64-wine:-** easy to configure and fast with good compatibility using newer version of wine and box64, support most graphic drivers for both termux glibc and proot **[Install From Here](https://github.com/ar37-rs/xow64-wine)**

#### There is three type of wine intallation options

- **Native:-** it can run apps based on your cpu architecture, like in arm based cpu you can only install windows **[arm apps](https://armrepo.ver.lt/)**
- **Mobox:-** it can run x86_64 windows apps in aarch64 device with good performance
    > **:warning: You need to set up Mobox after the termux-desktop installation finishes [From Here](https://github.com/olegos2/mobox)**
- **Hangover-wine:-** do the same thing like mobox
