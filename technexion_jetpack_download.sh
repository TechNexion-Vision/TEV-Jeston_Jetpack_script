#!/bin/bash

TIME=$(date +'%Y%m%d')
CUR_DIR="$(pwd)/"
NV_TAG="jetson_35.3.1"
BRANCH="tn_l4t-r35.3.1.ga_kernel-5.10"
TEK_BRANCH="${BRANCH}_TEK-ORIN-a1"

VALID_TAG=("r35.3.ga")

USING_TAG=0

get_nvidia_jetpack() {
	echo -ne "\n### Get nvidia jetpack source code\n"
	JETPACK="https://developer.nvidia.com/downloads/embedded/l4t/r35_release_v3.1/release/jetson_linux_r35.3.1_aarch64.tbz2/"
	ROOTFS="https://developer.nvidia.com/downloads/embedded/l4t/r35_release_v3.1/release/tegra_linux_sample-root-filesystem_r35.3.1_aarch64.tbz2/"
	PUBLIC="https://developer.nvidia.com/downloads/embedded/l4t/r35_release_v3.1/sources/public_sources.tbz2/"
	HYNIX_16G_DRAM_PATCH_1="https://ftp.technexion.com/development_resources/NVIDIA/.TEK6100-ORIN-NX-hynix/overlay_35.3.1_Dave_20230704.tbz2"
	HYNIX_16G_DRAM_PATCH_2="https://ftp.technexion.com/development_resources/NVIDIA/.TEK6100-ORIN-NX-hynix/t234-dram-package-35.3.1.tbz2"

	wget $JETPACK -q --tries=10 -O jetpack.tbz2
	wget $ROOTFS -q --tries=10 -O rootfs.tbz2
	wget $PUBLIC -q --tries=10 -O public.tbz2

	tar -jxf jetpack.tbz2
	tar -jxf public.tbz2
	sudo tar -jxf rootfs.tbz2 -C Linux_for_Tegra/rootfs

	# overlay patch from NVIDIA, cover ORIN-NX 16G with hynix dram
	wget -q --no-check-certificate $HYNIX_16G_DRAM_PATCH_1 -O dram-patch-1.tbz2
	wget -q --no-check-certificate $HYNIX_16G_DRAM_PATCH_2 -O dram-patch-2.tbz2
	tar -jxf dram-patch-1.tbz2
	tar -jxf dram-patch-2.tbz2

	rm -rf jetpack.tbz2 rootfs.tbz2 public.tbz2 dram-patch-1.tbz2 dram-patch-2.tbz2

	cd ${CUR_DIR}
	echo -ne "done\n"
}

run_nvidia_script_and_sync_code() {
	echo -ne "\n### Run nvidia script to get require sources\n"
	cd Linux_for_Tegra/
	sudo ./apply_binaries.sh
	sudo ./tools/l4t_flash_prerequisites.sh

	echo -ne "\n### Clone nvidia source code\n"
	# tweak for prevent source_sync from return 1
	sed -i '80d' source_sync.sh
	./source_sync.sh -t ${NV_TAG}
	cd ${CUR_DIR}
	echo -ne "done\n"
}

sync_tn_source_code() {
	echo -ne "\n### Clone source code from Technexion github\n"

	echo -ne "# kernel\n"
	cd Linux_for_Tegra/sources/kernel/kernel-5.10/
	if [[ $USING_SSH -eq 0 ]];then
		git remote add tn-github https://github.com/TechNexion-Vision/TEV-Jetson_kernel.git
	else
		git remote add tn-github git@github.com:TechNexion-Vision/TEV-Jetson_kernel.git
	fi
	git fetch tn-github ${BRANCH}
	git checkout -b ${BRANCH} tn-github/${BRANCH}
	git fetch tn-github --tags
	if [[ $USING_TAG -eq 1 ]];then
		git reset --hard $TAG
	fi
	cd ${CUR_DIR}

	echo -ne "# dts\n"
	if [[ $SOM == "Orin" ]]; then
		cd Linux_for_Tegra/sources/hardware/nvidia/platform/t23x/p3768/kernel-dts/
		if [[ $USING_SSH -eq 0 ]];then
			git remote add tn-github https://github.com/TechNexion-Vision/TEV-JetsonOrin-Nano_device-tree.git
		else
			git remote add tn-github git@github.com:TechNexion-Vision/TEV-JetsonOrin-Nano_device-tree.git
		fi
	fi
	git fetch tn-github ${BRANCH}
	git checkout -b ${BRANCH} tn-github/${BRANCH}
	git fetch tn-github --tags
	if [[ $USING_TAG -eq 1 ]];then
		git reset --hard $TAG
	fi
	cd ${CUR_DIR}

	echo -ne "# technexion camera drivers\n"
	cd Linux_for_Tegra/sources/kernel/
	if [[ $USING_SSH -eq 0 ]];then
		git clone https://github.com/TechNexion-Vision/TEV-Jetson_Camera_driver.git technexion
	else
		git clone git@github.com:TechNexion-Vision/TEV-Jetson_Camera_driver.git technexion
	fi
	cd technexion
	git checkout $BRANCH
	if [[ $USING_TAG -eq 1 ]];then
		git reset --hard $TAG
	fi
	cd ${CUR_DIR}

	echo -ne "# technexion pinmux file(xlsm)\n"
	cd Linux_for_Tegra/sources/
	if [[ $SOM == "Orin" ]]; then
		if [[ $USING_SSH -eq 0 ]];then
			git clone https://github.com/TechNexion-Vision/TEV-JetsonOrin-Nano_pinmux.git TEK-ORIN_Orin-Nano_pinmux
		else
			git clone git@github.com:TechNexion-Vision/TEV-JetsonOrin-Nano_pinmux.git TEK-ORIN_Orin-Nano_pinmux
		fi
		cd TEK-ORIN_Orin-Nano_pinmux
		git checkout ${TEK_BRANCH}
		if [[ $USING_TAG -eq 1 ]];then
			git reset --hard ${TEK_TAG}
		fi
	fi
	cd ${CUR_DIR}

	echo -ne "done\n"
}

create_gcc_tool_chain () {
	echo -ne "\n### Download gcc tool chain\n"
	cd Linux_for_Tegra/sources/kernel/
	mkdir -p gcc_tool_chain
	cd gcc_tool_chain/
	GCC_TOOL_CHAIN="$(pwd)"
	wget -q --no-check-certificate https://developer.nvidia.com/embedded/jetson-linux/bootlin-toolchain-gcc-93 --tries=10
	tar -zxf bootlin-toolchain-gcc-93
	echo -ne "done\n"
	cd ${CUR_DIR}
}

create_kernel_compile_script () {
	echo -ne "\n### Download kernel compile script\n"
	cd Linux_for_Tegra/sources/kernel/kernel-5.10/
	echo -e "#!/bin/bash -e" > environment_arm64_gcc7.sh
	echo -e "export GCC_DIR=${GCC_TOOL_CHAIN}" >> environment_arm64_gcc7.sh
	echo -e "export ARCH=arm64" >> environment_arm64_gcc7.sh
	echo -e "export CROSS_COMPILE=\${GCC_DIR}/bin/aarch64-buildroot-linux-gnu-" >> environment_arm64_gcc7.sh
	echo -e "export CROSS_COMPILE_AARCH64_PATH=\${GCC_DIR}/" >> environment_arm64_gcc7.sh
	chmod 777 environment_arm64_gcc7.sh

	echo -e "#!/bin/bash -e\n" > compile_kernel.sh
	echo -e "source environment_arm64_gcc7.sh" >> compile_kernel.sh
	echo -e "make tegra_tn_defconfig\n" >> compile_kernel.sh
	echo -e "#Compile kernel" >> compile_kernel.sh
	echo -e "make LOCALVERSION=-tegra -j\$(nproc) Image" >> compile_kernel.sh
	echo -e "#Compile DTBs" >> compile_kernel.sh
	echo -e "make LOCALVERSION=-tegra -j\$(nproc) dtbs" >> compile_kernel.sh
	echo -e "#Compile modules" >> compile_kernel.sh
	echo -e "make LOCALVERSION=-tegra -j\$(nproc) modules\n" >> compile_kernel.sh
	echo -e "#Install kernel modules" >> compile_kernel.sh
	echo -e "mkdir -p ../modules" >> compile_kernel.sh
	echo -e "cd ../modules" >> compile_kernel.sh
	echo -e "if [[ ! -f kernel_supplements.tbz2 ]]" >> compile_kernel.sh
	echo -e "then" >> compile_kernel.sh
	echo -e "cp -rv ../../../kernel/kernel_supplements.tbz2 ./" >> compile_kernel.sh
	echo -e "fi\n" >> compile_kernel.sh
	echo -e "if [[ ! -f kernel_display_supplements.tbz2 ]]" >> compile_kernel.sh
	echo -e "then" >> compile_kernel.sh
	echo -e "cp -rv ../../../kernel/kernel_display_supplements.tbz2 ./" >> compile_kernel.sh
	echo -e "fi\n" >> compile_kernel.sh
	echo -e "tar -jxf kernel_supplements.tbz2" >> compile_kernel.sh
	echo -e "tar -jxf kernel_display_supplements.tbz2" >> compile_kernel.sh
	echo -e "cd ../kernel-5.10" >> compile_kernel.sh
	echo -e "make LOCALVERSION=-tegra INSTALL_MOD_PATH=../modules modules_install" >> compile_kernel.sh
	chmod 777 compile_kernel.sh

	cd ${CUR_DIR}
	echo -ne "done\n"
}

compile_kernel (){
	echo -ne "\n### compile kernel\n"
	cd Linux_for_Tegra/sources/kernel/kernel-5.10/
	./compile_kernel.sh

	cd ${CUR_DIR}
	echo -ne "done\n"
}

create_demo_image (){
	echo -ne "\n### create demo_image\n"
	# copy kernel image
	sudo cp -rp Linux_for_Tegra/sources/kernel/kernel-5.10/arch/arm64/boot/Image Linux_for_Tegra/kernel/
	sudo cp -rp Linux_for_Tegra/sources/kernel/kernel-5.10/arch/arm64/boot/Image Linux_for_Tegra/rootfs/boot/
	sudo rm -rf Linux_for_Tegra/kernel/Image.gz

	# copy kernel modules and don't forget the origin ones
	sudo cp -rp Linux_for_Tegra/sources/kernel/modules/lib/modules/ Linux_for_Tegra/rootfs/lib/
	# copy device-tree
	if [[ $SOM == "Orin" ]];then
		sudo cp -rp Linux_for_Tegra/sources/kernel/kernel-5.10/arch/arm64/boot/dts/nvidia/tegra234-p3767-000*-tek-orin-a1.dtb Linux_for_Tegra/kernel/dtb/
		sudo cp -rp Linux_for_Tegra/sources/kernel/kernel-5.10/arch/arm64/boot/dts/nvidia/tegra234-p3767-000*-tek-orin-a1.dtb Linux_for_Tegra/rootfs/boot/
		sudo cp -rp Linux_for_Tegra/sources/kernel/kernel-5.10/arch/arm64/boot/dts/nvidia/tegra234-p3767-0003-p3768-0000-a0-*.dtb Linux_for_Tegra/kernel/dtb/
		sudo cp -rp Linux_for_Tegra/sources/kernel/kernel-5.10/arch/arm64/boot/dts/nvidia/tegra234-p3767-0003-p3768-0000-a0-*.dtb Linux_for_Tegra/rootfs/boot/
	fi
	# copy pinmux file
	if [[ $SOM == "Orin" ]]; then
		sudo cp -rp Linux_for_Tegra/sources/TEK-ORIN_Orin-Nano_pinmux/Orin-tek-orin-a1-gpio-default.dtsi Linux_for_Tegra/bootloader/
		sudo cp -rp Linux_for_Tegra/sources/TEK-ORIN_Orin-Nano_pinmux/Orin-tek-orin-a1-pinmux.dtsi Linux_for_Tegra/bootloader/t186ref/BCT/
		# change firewall rule for PWM7
		sudo sed -i '25654d' Linux_for_Tegra/bootloader/tegra234-firewall-config-base.dtsi
		sudo sed -i '25654i \ \ \ \ \ \ \ \ \ \ \ \ value = <0x0010000a>;' Linux_for_Tegra/bootloader/tegra234-firewall-config-base.dtsi
		sudo sed -i '25659d' Linux_for_Tegra/bootloader/tegra234-firewall-config-base.dtsi
		sudo sed -i '25659i \ \ \ \ \ \ \ \ \ \ \ \ value = <0x0010000a>;' Linux_for_Tegra/bootloader/tegra234-firewall-config-base.dtsi
	fi

	# copy install VizionViewer service
	if [[ $USING_SSH -eq 0 ]];then
		git clone https://github.com/TechNexion-Vision/TEV-Jetson_install_VizionViewer.git VizionViewer
	else
		git clone git@github.com:TechNexion-Vision/TEV-Jetson_install_VizionViewer.git VizionViewer
	fi
	cd VizionViewer
	git checkout ${BRANCH}
	if [[ $USING_TAG -eq 1 ]];then
		git reset --hard ${TAG}
	fi
	cd ${CUR_DIR}
	sudo cp -rp VizionViewer/etc/ Linux_for_Tegra/rootfs/
	sudo cp -rp VizionViewer/usr/ Linux_for_Tegra/rootfs/
	rm -rf VizionViewer/

	# dwonload VizionViewer
	if [[ $USING_TAG -eq 1 ]];then
		case $TAG in
			r35.3.ga)
				VV_URL='https://ftp.technexion.com/vizionviewer/linux_nvidia_jetson/focal/vizionviewer_24.05.1_jetson_focal.tar.xz'
				;;
			*)
				# Let VV_URL empty, cause error when try to download
				;;
		esac
	else
		# download the lastest VizionViewer
		VV_URL='https://ftp.technexion.com/vizionviewer/linux_nvidia_jetson/focal/'
		VV_LIST=()
		VV_LIST_VER=()
		MAX_VER=0
		VV=$(curl ${VV_URL}|grep -Poi "href=\"vizionviewer_.*_focal.tar.xz\"" | cut -d '"' -f 2)
		for i in ${VV[@]}
		do
			if [[ $i == vizionviewer* ]];then
				VV_LIST+=(${i})
			fi
		done

		for i in ${VV_LIST[@]}
		do
			VV_LIST_VER+=($(echo $i|grep -Poi "_[\d|\.]*"| sed 's|_||g'| sed 's|\.||g'))
		done

		for i in ${VV_LIST_VER[@]}
		do
			if [[ ${i} -gt ${MAX_VER} ]];then
				MAX_VER=${i}
			fi
		done

		for ((i=0;i<${#VV_LIST_VER[@]};i++))
		do
			if [[ ${VV_LIST_VER[$i]} == $MAX_VER ]];then
				VV_URL+=${VV_LIST[$i]}
			fi
		done
	fi
	wget -c -t --no-check-certificate ${VV_URL}
	sudo mv vizionviewer*.tar.xz Linux_for_Tegra/rootfs/usr/share/vizionviewer/

	# copy QCA9377 firmware from github
	git clone https://git.codelinaro.org/clo/ath-firmware/ath10k-firmware.git QCA9377_WIFI
	git clone https://oauth2:SbtQ_mC4fvJRA88_9jB7@gitlab.com/technexion-imx/qca_firmware.git QCA9377_BT
	sudo cp -rp QCA9377_WIFI/QCA9377/hw1.0/board-2.bin Linux_for_Tegra/rootfs/lib/firmware/ath10k/QCA9377/hw1.0
	sudo cp -rp QCA9377_WIFI/QCA9377/hw1.0/board.bin Linux_for_Tegra/rootfs/lib/firmware/ath10k/QCA9377/hw1.0
	sudo cp -rp QCA9377_WIFI/LICENSE.qca_firmware Linux_for_Tegra/rootfs/lib/firmware/ath10k/QCA9377/hw1.0
	sudo cp -rp QCA9377_WIFI/QCA9377/hw1.0/CNSS.TF.1.0/firmware-5.bin_CNSS.TF.1.0-00267-QCATFSWPZ-1 Linux_for_Tegra/rootfs/lib/firmware/ath10k/QCA9377/hw1.0/firmware-5.bin
	sudo cp -rp QCA9377_BT/qca/notice.txt Linux_for_Tegra/rootfs/lib/firmware/qca
	sudo cp -rp QCA9377_BT/qca/nvm_usb_00000302.bin Linux_for_Tegra/rootfs/lib/firmware/qca
	sudo cp -rp QCA9377_BT/qca/rampatch_usb_00000302.bin Linux_for_Tegra/rootfs/lib/firmware/qca
	rm -rf QCA9377_WIFI
	rm -rf QCA9377_BT

	# copy change boot config
	cd Linux_for_Tegra/rootfs/boot/extlinux/
	# close quiet for more dmesg
	sudo sed -i 's/APPEND \${cbootargs} quiet/APPEND \${cbootargs}/' extlinux.conf
	cd ${CUR_DIR}

	# create default user and auto login
	sed -zi 's|show_eula\n|#show_eula\n|' Linux_for_Tegra/tools/l4t_create_default_user.sh
	sudo Linux_for_Tegra/tools/l4t_create_default_user.sh -u ubuntu -p ubuntu -a
	sed -zi 's|#show_eula\n|show_eula\n|' Linux_for_Tegra/tools/l4t_create_default_user.sh

	# change background to TecnNexion logo
	wget -c -t 5 --no-check-certificate https://ftp.technexion.com/development_resources/.technexion_logo/PPT2.jpg
	sudo mv PPT2.jpg Linux_for_Tegra/rootfs/usr/share/backgrounds/
	sudo sed -i 's|nv_background="/usr/share/backgrounds/NVIDIA_Wallpaper.jpg"|nv_background="/usr/share/backgrounds/PPT2.jpg"|' Linux_for_Tegra/rootfs/etc/xdg/autostart/nvbackground.sh

	# tweak mb2 dts to make HDMI support 4K
	sed -i '8i\\' Linux_for_Tegra/bootloader/t186ref/BCT/tegra234-mb2-bct-scr-p3767-0000.dts
	sed -i '8i\ \ \ \ \ \ \ \ };' Linux_for_Tegra/bootloader/t186ref/BCT/tegra234-mb2-bct-scr-p3767-0000.dts
	sed -i '8i\ \ \ \ \ \ \ \ \ \ \ \ value = <0x38009696>;' Linux_for_Tegra/bootloader/t186ref/BCT/tegra234-mb2-bct-scr-p3767-0000.dts
	sed -i '8i\ \ \ \ \ \ \ \ \ \ \ \ exclusion-info = <2>;' Linux_for_Tegra/bootloader/t186ref/BCT/tegra234-mb2-bct-scr-p3767-0000.dts
	sed -i '8i\ \ \ \ \ \ \ \ reg@322 { /* GPIO_M_SCR_00_0 */' Linux_for_Tegra/bootloader/t186ref/BCT/tegra234-mb2-bct-scr-p3767-0000.dts

	# download disk image creator script
	if [[ $USING_SSH -eq 0 ]];then
		git clone https://github.com/TechNexion-Vision/TEV-Jetson_disk_image_creator.git TEV-Jetson_disk_image_creator
	else
		git clone git@github.com:TechNexion-Vision/TEV-Jetson_disk_image_creator.git TEV-Jetson_disk_image_creator
	fi
	cd TEV-Jetson_disk_image_creator
	git checkout ${BRANCH}
	if [[ $USING_TAG -eq 1 ]];then
		git reset --hard ${TAG}
	fi
	cd ${CUR_DIR}
	sudo cp -rp TEV-Jetson_disk_image_creator/jetson-disk-image-creator.sh Linux_for_Tegra/tools/
	rm -rf TEV-Jetson_disk_image_creator/

	# copy all machine conf to folder
	cp -rv tn-*.conf Linux_for_Tegra/

	# create new demo_image
	cd Linux_for_Tegra/
	if [[ ${qspi_only} -eq 1 ]];then
		sudo ./tools/kernel_flash/l4t_initrd_flash.sh \
			-p "-c bootloader/t186ref/cfg/flash_t234_qspi.xml --no-systemimg" \
			--showlogs --no-flash --network usb0 ${board_conf} internal
	else
		sudo ./tools/kernel_flash/l4t_initrd_flash.sh --external-device ${rootfs_dev_p1[0]} -c tools/kernel_flash/flash_l4t_external.xml \
			-p "-c bootloader/t186ref/cfg/flash_t234_qspi.xml" \
			--showlogs --no-flash --network usb0 ${board_conf} internal
	fi
	cd ${CUR_DIR}
	echo -ne "done\n"
}

usage() {
	echo -e "$0 \ndownload the Technexion Jetpack -b <baseboard>" 1>&2
	echo "-b: baseboard <TEK6020-ORIN-NANO/ TEK6040-ORIN-NANO/ TEK6070-ORIN-NX/ TEK6100-ORIN-NX/ TEK6100-ORIN-NX-HYNIX" 1>&2
	echo "               TEV-RPI22-TEVI/ TEV-RPI22-TEVS/ VLS3-ORIN-EVK-VLS3>" 1>&2
	echo "" 1>&2
	echo "Jetson Orin series:" 1>&2
	echo "TEK6020-ORIN-NANO| TEK6040-ORIN-NANO| TEK6070-ORIN-NX| TEK6100-ORIN-NX| TEK6100-ORIN-NX-HYNIX" 1>&2
	echo "" 1>&2
	echo "Jetson Orin EVK series:" 1>&2
	echo "TEV-RPI22-TEVI| TEV-RPI22-TEVS| VLS3-ORIN-EVK-VLS3" 1>&2
	echo "" 1>&2
	echo "-t: tag for sync code:" 1>&2
	echo "r35.3.ga" 1>&2
	echo "" 1>&2
	echo "--qspi-only: do not create/ flash rootfs, for qspi image only" 1>&2
	exit 1
}

setup_env_vars () {
	case $1 in
		TEK6020-ORIN-NANO)
			board_conf="tn-tek6020-orin-nano"
			rootfs_dev=("NVMe" "USB")
			rootfs_dev_p1=("nvme0n1p1" "sda1")
			;;
		TEK6040-ORIN-NANO)
			board_conf="tn-tek6040-orin-nano"
			rootfs_dev=("NVMe" "USB")
			rootfs_dev_p1=("nvme0n1p1" "sda1")
			;;
		TEK6070-ORIN-NX)
			board_conf="tn-tek6070-orin-nx"
			rootfs_dev=("NVMe" "USB")
			rootfs_dev_p1=("nvme0n1p1" "sda1")
			;;
		TEK6100-ORIN-NX)
			board_conf="tn-tek6100-orin-nx"
			rootfs_dev=("NVMe" "USB")
			rootfs_dev_p1=("nvme0n1p1" "sda1")
			;;
		TEK6100-ORIN-NX-HYNIX)
			board_conf="tn-tek6100-orin-nx-hynix"
			rootfs_dev=("NVMe" "USB")
			rootfs_dev_p1=("nvme0n1p1" "sda1")
			;;
		TEV-RPI22-TEVI)
			board_conf="tn-tev-rpi22-tevi"
			rootfs_dev=("SD" "USB")
			rootfs_dev_p1=("mmcblk1p1" "sda1")
			;;
		TEV-RPI22-TEVS)
			board_conf="tn-tev-rpi22-tevs"
			rootfs_dev=("SD" "USB")
			rootfs_dev_p1=("mmcblk1p1" "sda1")
			;;
		VLS3-ORIN-EVK-VLS3)
			board_conf="tn-vls3-orin-evk-vls3"
			rootfs_dev=("SD" "USB")
			rootfs_dev_p1=("mmcblk1p1" "sda1")
			;;
		*)
			echo -e "invalid baseboard option!!\n"
			usage
			;;
	esac
}

do_job () {
	CUR_DIR="$(pwd)/"
	get_nvidia_jetpack
	run_nvidia_script_and_sync_code

	sync_tn_source_code
	create_gcc_tool_chain

	create_kernel_compile_script
	compile_kernel

	create_demo_image

	cd Linux_for_Tegra/
	cd ${CUR_DIR}
	echo -ne "\n### Finish\n"
}

# default variables
qspi_only=0

### Script start from here
set -e

Error_appears () {
    if [ $? -ne 0 ]
    then
        echo "##### script was running failed due to previous error!! #####"
    fi
}
trap Error_appears EXIT

if [ "$(id -u)" = "0" ]; then
	echo "This script can not be run as root"
	exit 1
fi

while getopts ":b:t:-:" o; do
	case "${o}" in
	b)
		b=${OPTARG}; setup_env_vars ${b}
		;;
	t)
		USING_TAG=1
		for k in "${VALID_TAG[@]}"; do
			if [[ "$k" == "${OPTARG}" ]]; then
				t=${OPTARG}
				break
			fi
		done
		if [[ -z ${t} ]];then
			echo -e "invalid tag option!!\n"
			echo -e "If you want to using no tag, just don't add this option!!\n"
			usage
		fi
		;;
	-) case ${OPTARG} in
		qspi-only)
			qspi_only=1
			;;
		*) usage allunknown 1; ;;
		esac;;
        *)
		usage
		;;
	esac
done
shift $((OPTIND-1))

if [ -z "${b}" ]; then
	echo -e "### lack of option\n\n" && usage
fi

echo valid input: b=$b

if [[ $b == *"ORIN"* ]]; then
	SOM=Orin
elif [[ $b == *"RPI22"* ]]; then
	SOM=Orin
fi

if [ -z "${t}" ]; then
	echo -e "### lack of tag, using lastest code.\n\n"
else
	echo "valid input: t=$t"
	TAG=$t
	TEK_TAG="${TAG}_TEK-ORIN-a1"
fi


# install build require package
echo -ne "####install build require package\n"
sudo apt-get update -y
sudo apt-get install -y qemu-user-static bc kmod flex
sudo apt-get install -y gawk wget git git-core diffstat unzip texinfo gcc-multilib build-essential \
chrpath socat cpio python-is-python3 python3 python3-pip python3-pexpect \
python3-git python3-jinja2 libegl1-mesa rsync bc bison \
xz-utils debianutils iputils-ping libsdl1.2-dev xterm \
language-pack-en coreutils texi2html file docbook-utils \
help2man desktop-file-utils \
libgl1-mesa-dev libglu1-mesa-dev mercurial autoconf automake \
groff curl lzop asciidoc u-boot-tools libreoffice-writer \
sshpass ssh-askpass zip xz-utils kpartx vim screen libssl-dev \
abootimg nfs-kernel-server

if [[ $(ssh -T -y git@github.com -o StrictHostKeyChecking=no; echo $?) -eq 1 ]];then
	echo -e "check github HostKey success, using ssh to download code.\n"
	USING_SSH=1
else
	echo -e "check github HostKey failed, using Https to download code.\n"
	USING_SSH=0
fi

do_job
