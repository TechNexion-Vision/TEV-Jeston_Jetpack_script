![video_orin-Banner-TEK(1) >](https://github.com/TechNexion-Vision/TEV-Jetson_Jetpack_script/assets/83322668/f699fae3-22a0-4eb0-9334-023286b953ca)

This script contains a complete system package that enables your Jeston Jetpack to directly support TechNexion embedded vision devices.

## 1. Prepare ubuntu environment
Download Ubuntu 20.04/ 22.04 iso file from [ubuntu web site](https://ubuntu.com/download/desktop).

This script supports native Ubuntu or Ubuntu VM.

## 2. Create TN Jetpack base on your device.
### Prepare git command in your ubuntu
```Bash
$ sudo apt-get update -y
$ sudo apt-get install git -y
```

### Create the nvidia workspace folder
```Bash
# Select one folder for Nvidia workspace
$ cd <workspace>
$ mkdir <nvidia_folder>
```

### Download the TN Jetpack
```Bash
$ git clone https://github.com/TechNexion-Vision/TEV-Jetson_Jetpack_script.git

# Copy script and conf file to your work folder
$ cp -rv TEV-Jetson_Jetpack_script/technexion_jetpack_download.sh <nvidia_folder>
$ cp -rv TEV-Jetson_Jetpack_script/*conf <nvidia_folder>
$ cd <nvidia_folder>
```
### run the script
```Bash
# Run the script to download Jetpack and Technexion sources
# example1:
$ ./technexion_jetpack_download.sh -b TEK6100-ORIN-NX
# example2:
$ ./technexion_jetpack_download.sh -b VLS3-ORIN-EVK-VLS3
```
```bash
# you can check all the option once you enter the wrong option.
$ ./technexion_jetpack_download.sh 
download the Technexion Jetpack -b <baseboard>
-b: baseboard <TEK6020-ORIN-NANO/ TEK6040-ORIN-NANO/ TEK6070-ORIN-NX/ TEK6100-ORIN-NX
               TEV-RPI22-TEVI/ TEV-RPI22-TEVS/ VLS3-ORIN-EVK-VLS3/ VLS3-ORIN-EVK-VLI>

Jetson Orin series:
TEK6020-ORIN-NANO| TEK6040-ORIN-NANO| TEK6070-ORIN-NX| TEK6100-ORIN-NX

Jetson Orin EVK series:
TEV-RPI22-TEVI| TEV-RPI22-TEVS| VLS3-ORIN-EVK-VLS3| VLS3-ORIN-EVK-VLI

-t: tag for sync code <>

--qspi-only: do not create/ flash rootfs, for qspi image only
```

## 3. Flash demo image from TEV-Jetpack

### Go to the main folder
```Bash
$ cd <nvidia_folder>/Linux_for_Tegra/
```

### Enter Recovery mode
1. **Connect** to computer via **M-USB1**.
2. Press **'Recovery**' button and '**Reset**' button **at the same time**.
3. Release '**Reset**' button.
4. Relesee '**Recovery**' button.
5. Check wether the device is connected.
```Bash
$ lsusb
Bus 001 Device 012: ID 0955:7e19 NVIDIA Corp. APX
```

### Flash demo image from L4T
* For Orin-Nano/ NX:

|  Product Name   | board_conf  | default storage |
|  ----  | ----  | ---- |
| TEK6100-ORIN-NX  | tn-tek6100-orin-nx | nvme0n1p1 |
| TEK6070-ORIN-NX  | tn-tek6070-orin-nx | nvme0n1p1 |
| TEK6040-ORIN-NANO  | tn-tek6040-orin-nano | nvme0n1p1 |
| TEK6020-ORIN-NANO  | tn-tek6020-orin-nano | nvme0n1p1 |
| VLS3-ORIN-EVK-VLS3  | tn-vls3-orin-evk-vls3 | mmcblk1p1 |
| TEV-RPI22-TEVI  | tn-tev-rpi22-tevi | mmcblk1p1 |
| TEV-RPI22-TEVS  | tn-tev-rpi22-tevS | mmcblk1p1 |

```Bash
# Please set the conf according to above table (<storage>, <board_conf>)
$ sudo ./tools/kernel_flash/l4t_initrd_flash.sh --external-device <storage> -c tools/kernel_flash/flash_l4t_external.xml \
	-p "-c bootloader/t186ref/cfg/flash_t234_qspi.xml" \
	--showlogs --no-flash --network usb0 <board_conf> internal
```
<br />
