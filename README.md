# Jeston Jetpack for TN embedded Vision script

[![Producer: Technexion](https://img.shields.io/badge/Producer-Technexion-blue.svg)](https://www.technexion.com)
[![License: GPL v2](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)

This script contains a complete system package that enables your Jeston Jetpack to directly support TechNexion embedded vision devices.

## 1. Install required packages
```coffeescript
$: sudo apt-get install gawk wget git git-core diffstat unzip texinfo gcc-multilib build-essential \
chrpath socat cpio python python3 python3-pip python3-pexpect \
python3-git python3-jinja2 libegl1-mesa pylint3 rsync bc bison \
xz-utils debianutils iputils-ping libsdl1.2-dev xterm \
language-pack-en coreutils texi2html file docbook-utils \
python-pysqlite2 help2man desktop-file-utils \
libgl1-mesa-dev libglu1-mesa-dev mercurial autoconf automake \
groff curl lzop asciidoc u-boot-tools libreoffice-writer \
sshpass ssh-askpass zip xz-utils kpartx vim screen flex
```

## 2. Create TEV-Jetpack base on your device.

### Create and enter the nvidia workspace folder
```coffeescript
$ mkdir <nvidia_folder> && cd <nvidia_folder>
```

### Download the TN-Jetpack using the script
Download script from [raw.github](https://raw.githubusercontent.com/TechNexion-Vision/TEV-Jetson_Jetpack_script/master/technexion_jetpack_download_pre-release.sh) and run.
```coffeescript
# Change the script permission
$ sudo chmod 777 technexion_jetpack_download_pre-release.sh

# Run the script to download Jetpack and Technexion sources
$ ./technexion_jetpack_download_pre-release.sh

# chosing your SOC and board.
# 1. TEK3-NVJETSON with Jetson Xavier Nx
# 2. TEK3-NVJETSON with Jetson Nano
# 3. TEK8-NVJETSON with Jetson Xavier Nx
```
## 2. Flash demo image from TEV-Jetpack

### Go to the main folder
```coffeescript
$ cd <nvidia_folder>/Linux_for_Tegra/
```

### Enter Recovery mode
1. **Connect** to computer via **M-USB1**.
2. Press **'Recovery**' button and '**Reset**' button **at the same time**.
3. Release '**Reset**' button.
4. Relesee '**Recovery**' button.
5. Check wether the device is connected.
```coffeescript
$ lsusb
Bus 001 Device 012: ID 0955:7e19 NVIDIA Corp. APX
```

### Flash demo image 
Demo image is already in <nvidia_folder>/Linux_for_Tegra/bootloader/, named system.img.

* For Xavier-NX
```coffeescript
$ sudo ./flash.sh -r jetson-xavier-nx-devkit-emmc mmcblk0p1 
```

* For Nano
```coffeescript
$ sudo ./flash.sh -r jetson-nano-devkit-emmc mmcblk0p1 
```
<br />

## 3. Login to device CUI/ GUI(console/ display)
After flash, you will see this on CUI:
```
[   31.893157] Please complete system configuration setup on desktop to proceed...
```
You need to **[follow the step](https://www.linuxtechi.com/ubuntu-18-04-lts-desktop-installation-guide-screenshots/)** to creat system configuration **on GUI**.
(Need to prepare **USB keyboard/ mouse**, and **DP monitor**.)

And you can login GUI/ CUI with your account.
> **With TEK8-NVJETSON**
> 
> It will flash FPGA firmware after you set system configuration.
> Reboot after finish, and this only do it once.

