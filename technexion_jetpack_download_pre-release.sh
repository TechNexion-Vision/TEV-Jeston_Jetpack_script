#!/bin/bash

TIME=$(date +'%Y%m%d')
CUR_DIR="$(pwd)/"
NV_TAG="tegra-l4t-r32.7.1"
TAG="pre-release"
TEK3_TAG="${TAG}_TEK3-NVJETSON-a1"
TEK8_TAG="${TAG}_TEK8-NX210V-a1"
BRANCH="tn_l4t-r32.7.1_kernel-4.9"
TEK3_BRANCH="${BRANCH}_TEK3-NVJETSON-a1"
TEK8_BRANCH="${BRANCH}_TEK8-NX210V-a1"
# Wether using ssh to download github source code
USING_SSH=0

# Wether using tag to download stable release
USING_TAG=1

get_nvidia_jetpack() {
	echo -ne "\n### Get nvidia jetpack source code\n"
	if [[ $OPTION -eq 2 ]];then
		echo -ne "Download Nano Jetpack\n"
		JETPACK="https://developer.nvidia.com/embedded/l4t/r32_release_v7.1/t210/jetson-210_linux_r32.7.1_aarch64.tbz2"
		ROOTFS="https://developer.nvidia.com/embedded/l4t/r32_release_v7.1/t210/tegra_linux_sample-root-filesystem_r32.7.1_aarch64.tbz2"
		PUBLIC="https://developer.nvidia.com/embedded/l4t/r32_release_v7.1/sources/t210/public_sources.tbz2"
	else
		echo -ne "Download Xavier NX Jetpack\n"
		JETPACK="https://developer.nvidia.com/embedded/l4t/r32_release_v7.1/t186/jetson_linux_r32.7.1_aarch64.tbz2"
		ROOTFS="https://developer.nvidia.com/embedded/l4t/r32_release_v7.1/t186/tegra_linux_sample-root-filesystem_r32.7.1_aarch64.tbz2"
		PUBLIC="https://developer.nvidia.com/embedded/l4t/r32_release_v7.1/sources/t186/public_sources.tbz2"
	fi
    
	wget $JETPACK -q --tries=10 -O jetpack.tbz2
	wget $ROOTFS -q --tries=10 -O rootfs.tbz2
	wget $PUBLIC -q --tries=10 -O public.tbz2

	tar -jxf jetpack.tbz2
	tar -jxf public.tbz2
	sudo tar -jxf rootfs.tbz2 -C Linux_for_Tegra/rootfs

	rm -rf jetpack.tbz2 rootfs.tbz2 public.tbz2
	cd ${CUR_DIR}
	echo -ne "done\n"
}

run_nvidia_script_and_sync_code() {
	echo -ne "\n### Run nvidia script to get require sources\n"
	cd Linux_for_Tegra/
	sudo ./apply_binaries.sh

	echo -ne "\n### Clone nvidia source code\n"
	# tweak for nvidia script error
	sed -i 's/k\:hardware\/nvidia\/platform\/t19x\/galen-industrial-dts/k\:hardware\/nvidia\/platform\/t19x\/galen-industrial/' source_sync.sh
	./source_sync.sh -t ${NV_TAG}
	cd ${CUR_DIR}
	echo -ne "done\n"
}

sync_tn_source_code() {
	echo -ne "\n### Clone source code from Technexion github\n"

	echo -ne "# kernel\n"
	cd Linux_for_Tegra/sources/kernel/kernel-4.9/
	if [[ $USING_SSH -eq 0 ]];then
		git remote add tn-github https://github.com/TechNexion-Vision/TEV-Jetson_kernel.git
	else
		git remote add tn-github git@github.com:TechNexion-Vision/TEV-Jetson_kernel.git
	fi
	git pull tn-github
	git checkout $BRANCH
	if [[ $USING_TAG -eq 1 ]];then
		git reset --hard $TAG
	fi
	cd ${CUR_DIR}

	echo -ne "# dts\n"
	if [[ $OPTION -eq 2 ]];then
		cd Linux_for_Tegra/sources/hardware/nvidia/platform/t210/porg/
		if [[ $USING_SSH -eq 0 ]];then
			git remote add tn-github https://github.com/TechNexion-Vision/TEV-JetsonNano_device-tree.git
		else
			git remote add tn-github git@github.com:TechNexion-Vision/TEV-JetsonNano_device-tree.git
		fi
	else
		cd Linux_for_Tegra/sources/hardware/nvidia/platform/t19x/jakku/kernel-dts/
		if [[ $USING_SSH -eq 0 ]];then
			git remote add tn-github https://github.com/TechNexion-Vision/TEV-JetsonXavier-NX_device-tree.git
		else
			git remote add tn-github git@github.com:TechNexion-Vision/TEV-JetsonXavier-NX_device-tree.git
		fi	
	fi
	git pull tn-github
	git checkout $BRANCH
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
	if [[ $OPTION -eq 1 ]];then
	if [[ $USING_SSH -eq 0 ]];then
		git clone https://github.com/TechNexion-Vision/TEV-JetsonXavier-NX_pinmux.git TEK3-NVJETSON_Xavier-NX_pinmux
	else
		git clone git@github.com:TechNexion-Vision/TEV-JetsonXavier-NX_pinmux.git TEK3-NVJETSON_Xavier-NX_pinmux
	fi
		cd TEK3-NVJETSON_Xavier-NX_pinmux
		git checkout ${TEK3_BRANCH}
		if [[ $USING_TAG -eq 1 ]];then
			git reset --hard ${TEK3_TAG}
		fi
	elif [[ $OPTION -eq 2 ]];then
		if [[ $USING_SSH -eq 0 ]];then
			git clone https://github.com/TechNexion-Vision/TEV-JetsonNano_pinmux.git TEK3-NVJETSON_Nano_pinmux
		else
			git clone git@github.com:TechNexion-Vision/TEV-JetsonNano_pinmux.git TEK3-NVJETSON_Nano_pinmux
		fi
		cd TEK3-NVJETSON_Nano_pinmux
		git checkout ${TEK3_BRANCH}
		if [[ $USING_TAG -eq 1 ]];then
			git reset --hard ${TEK3_TAG}
		fi
	elif [[ $OPTION -eq 3 ]];then
		if [[ $USING_SSH -eq 0 ]];then
			git clone https://github.com/TechNexion-Vision/TEV-JetsonXavier-NX_pinmux.git TEK8-NX210V_Xavier-NX_pinmux
		else
			git clone git@github.com:TechNexion-Vision/TEV-JetsonXavier-NX_pinmux.git TEK8-NX210V_Xavier-NX_pinmux
		fi
		cd TEK8-NX210V_Xavier-NX_pinmux
		git checkout ${TEK8_BRANCH}
		if [[ $USING_TAG -eq 1 ]];then
			git reset --hard ${TEK8_TAG}
		fi
	fi
	cd ${CUR_DIR}

	if [[ $OPTION -eq 2 ]];then
		echo -ne "# u-boot\n"
		cd Linux_for_Tegra/sources/u-boot/
		if [[ $USING_SSH -eq 0 ]];then
			git remote add tn-github https://github.com/TechNexion-Vision/TEV-JetsonNano_u-boot.git
		else
			git remote add tn-github git@github.com:TechNexion-Vision/TEV-JetsonNano_u-boot.git
		fi
		git pull tn-github
		git checkout ${TEK3_BRANCH}
		if [[ $USING_TAG -eq 1 ]];then
			git reset --hard ${TEK3_TAG}
		fi
		cd ${CUR_DIR}
	fi
	echo -ne "done\n"
}

create_gcc_tool_chain () {
	echo -ne "\n### Download gcc tool chain\n"
	cd Linux_for_Tegra/sources/kernel/
	mkdir -p gcc_tool_chain
	cd gcc_tool_chain/
	GCC_TOOL_CHAIN="$(pwd)/"
	wget -q --no-check-certificate https://releases.linaro.org/components/toolchain/binaries/7.4-2019.02/aarch64-linux-gnu/gcc-linaro-7.4.1-2019.02-x86_64_aarch64-linux-gnu.tar.xz --tries=10
	tar Jxf gcc-linaro-7.4.1-2019.02-x86_64_aarch64-linux-gnu.tar.xz
	echo -ne "done\n"
	cd ${CUR_DIR}
}

create_kernel_compile_script () {
	echo -ne "\n### Download kernel compile script\n"
	cd Linux_for_Tegra/sources/kernel/kernel-4.9/
	echo -e "#!/bin/bash" > environment_arm64_gcc7.sh
	echo -e "export GCC_DIR=${GCC_TOOL_CHAIN}" >> environment_arm64_gcc7.sh
	echo -e "export ARCH=arm64" >> environment_arm64_gcc7.sh
	echo -e "export CROSS_COMPILE=\${GCC_DIR}/gcc-linaro-7.4.1-2019.02-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-" >> environment_arm64_gcc7.sh
	echo -e "export CROSS_COMPILE_AARCH64_PATH=\${GCC_DIR}/gcc-linaro-7.4.1-2019.02-x86_64_aarch64-linux-gnu/" >> environment_arm64_gcc7.sh
	chmod 777 environment_arm64_gcc7.sh

	echo -e "#!/bin/bash\n" > compile_kernel.sh
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
	echo -e "make LOCALVERSION=-tegra INSTALL_MOD_PATH=../modules modules_install" >> compile_kernel.sh
	chmod 777 compile_kernel.sh

	cd ${CUR_DIR}
	echo -ne "done\n"
}

create_u-boot_compile_script () {
	echo -ne "\n### Download u-boot compile script\n"
	cd Linux_for_Tegra/sources/u-boot
	echo -e "#!/bin/bash" > environment_arm64_gcc7.sh
	echo -e "export GCC_DIR=${GCC_TOOL_CHAIN}" >> environment_arm64_gcc7.sh
	echo -e "export ARCH=arm64" >> environment_arm64_gcc7.sh
	echo -e "export CROSS_COMPILE=\${GCC_DIR}/gcc-linaro-7.4.1-2019.02-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-" >> environment_arm64_gcc7.sh
	echo -e "export CROSS_COMPILE_AARCH64_PATH=\${GCC_DIR}/gcc-linaro-7.4.1-2019.02-x86_64_aarch64-linux-gnu/" >> environment_arm64_gcc7.sh
	chmod 777 environment_arm64_gcc7.sh

	echo -e "#!/bin/bash\n" > compile_u-boot.sh
	echo -e "source environment_arm64_gcc7.sh" >> compile_u-boot.sh
	echo -e "make p3450-0000_defconfig\n" >> compile_u-boot.sh
	echo -e "make -j\$(nproc)" >> compile_u-boot.sh
	chmod 777 compile_u-boot.sh
	cd ${CUR_DIR}
	echo -ne "done\n"
}

compile_kernel_for_24_cam (){
	echo -ne "\n### compile tweak kernel for 24-cam\n"
	cd Linux_for_Tegra/sources/kernel/technexion/
	git checkout tn_l4t-r32.7.1_kernel-4.9_serdes_24cam
	cd ${CUR_DIR}

	cd Linux_for_Tegra/sources/kernel/kernel-4.9/
	./compile_kernel.sh
	# backup tweak kernel
	mv arch/arm64/boot/Image arch/arm64/boot/Image_24-cam
	cd ${CUR_DIR}

	cd Linux_for_Tegra/sources/kernel/technexion/
	git checkout $BRANCH
	cd ${CUR_DIR}
	echo -ne "done\n"
}

compile_kernel (){
	echo -ne "\n### compile kernel\n"
	cd Linux_for_Tegra/sources/kernel/kernel-4.9/
	./compile_kernel.sh

	cd ${CUR_DIR}
	echo -ne "done\n"
}

compile_u-boot (){
	echo -ne "\n### compile u-boot\n"
	cd Linux_for_Tegra/sources/u-boot
	./compile_u-boot.sh

	cd ${CUR_DIR}
	echo -ne "done\n"
}

create_demo_image (){
	echo -ne "\n### create demo_image\n"
	# copy kernel image
	sudo cp -rp Linux_for_Tegra/sources/kernel/kernel-4.9/arch/arm64/boot/Image Linux_for_Tegra/kernel/
	sudo cp -rp Linux_for_Tegra/sources/kernel/kernel-4.9/arch/arm64/boot/Image Linux_for_Tegra/rootfs/boot/
	if [[ $OPTION -eq 3 ]];then
		sudo cp -rp Linux_for_Tegra/sources/kernel/kernel-4.9/arch/arm64/boot/Image_24-cam Linux_for_Tegra/kernel/
		sudo cp -rp Linux_for_Tegra/sources/kernel/kernel-4.9/arch/arm64/boot/Image_24-cam Linux_for_Tegra/rootfs/boot/
	fi
	sudo rm -rf Linux_for_Tegra/kernel/Image.gz
	# copy kernel modules
	sudo cp -rp Linux_for_Tegra/sources/kernel/modules/lib/ Linux_for_Tegra/rootfs/
	# copy device-tree
	if [[ $OPTION -eq 2 ]];then
		sudo cp -rp Linux_for_Tegra/sources/kernel/kernel-4.9/arch/arm64/boot/dts/tegra210-tek3-nvjetson-a1.dtb Linux_for_Tegra/rootfs/boot/
	else
		sudo cp -rp Linux_for_Tegra/sources/kernel/kernel-4.9/arch/arm64/boot/dts/tegra194-p3668-tek3-nvjetson-a1.dtb Linux_for_Tegra/rootfs/boot/
		sudo cp -rp Linux_for_Tegra/sources/kernel/kernel-4.9/arch/arm64/boot/dts/tegra194-p3668-tek8-nx210v-a1.dtb Linux_for_Tegra/rootfs/boot/
		sudo cp -rp Linux_for_Tegra/sources/kernel/kernel-4.9/arch/arm64/boot/dts/tegra194-p3668-tek8-nx210v-a1-24-cam.dtb Linux_for_Tegra/rootfs/boot/
		# tweak: dp pinmux will use origin dtb, we must update it.
		sudo cp -rp Linux_for_Tegra/sources/kernel/kernel-4.9/arch/arm64/boot/dts/tegra194-p3668-all-p3509-0000.dtb Linux_for_Tegra/kernel/dtb/
	fi
	# copy u-boot.bin (tweak for TEK3-NVJETSON with Nano)
	if [[ $OPTION -eq 2 ]];then
		sudo cp -rp Linux_for_Tegra/sources/u-boot/u-boot.bin Linux_for_Tegra/bootloader/t210ref/p3450-0000/
	fi
	# copy pinmux file (Xavier-NX only)
	if [[ $OPTION -eq 1 ]];then
		sudo cp -rp Linux_for_Tegra/sources/TEK3-NVJETSON_Xavier-NX_pinmux/tegra19x-mb1-pinmux-p3668-a01.cfg Linux_for_Tegra/bootloader/t186ref/BCT/
	elif [[ $OPTION -eq 3 ]];then
		sudo cp -rp Linux_for_Tegra/sources/TEK8-NX210V_Xavier-NX_pinmux/tegra19x-mb1-pinmux-p3668-a01.cfg Linux_for_Tegra/bootloader/t186ref/BCT/
	fi
	# copy flash FPGA firmware service
	if [[ $OPTION -eq 3 ]];then
		if [[ $USING_SSH -eq 0 ]];then
			git clone https://github.com/TechNexion-Vision/TEV-JetsonXavier-NX_TEK8_FPGA_Flash.git FPGA
		else
			git clone git@github.com:TechNexion-Vision/TEV-JetsonXavier-NX_TEK8_FPGA_Flash.git FPGA
		fi
		cd FPGA
		git checkout ${TEK8_BRANCH}
		if [[ $USING_TAG -eq 1 ]];then
			git reset --hard ${TEK8_TAG}
		fi
		cd ${CUR_DIR}
		sudo cp -rp FPGA/etc/ Linux_for_Tegra/rootfs/
		sudo cp -rp FPGA/usr/ Linux_for_Tegra/rootfs/
		rm -rf FPGA/
	fi

	# copy QCA9377 firmware from github
	git clone https://github.com/kvalo/ath10k-firmware.git QCA9377_WIFI
	git clone https://oauth2:SbtQ_mC4fvJRA88_9jB7@gitlab.com/technexion-imx/qca_firmware.git QCA9377_BT
	sudo cp -rv QCA9377_WIFI/QCA9377/hw1.0/board-2.bin Linux_for_Tegra/rootfs/lib/firmware/ath10k/QCA9377/hw1.0
	sudo cp -rv QCA9377_WIFI/QCA9377/hw1.0/board.bin Linux_for_Tegra/rootfs/lib/firmware/ath10k/QCA9377/hw1.0
	sudo cp -rv QCA9377_WIFI/LICENSE.qca_firmware Linux_for_Tegra/rootfs/lib/firmware/ath10k/QCA9377/hw1.0
	sudo cp -rv QCA9377_WIFI/QCA9377/hw1.0/CNSS.TF.1.0/firmware-5.bin_CNSS.TF.1.0-00267-QCATFSWPZ-1 Linux_for_Tegra/rootfs/lib/firmware/ath10k/QCA9377/hw1.0/firmware-5.bin
	sudo cp -rv QCA9377_BT/qca/notice.txt Linux_for_Tegra/rootfs/lib/firmware/qca
	sudo cp -rv QCA9377_BT/qca/nvm_usb_00000302.bin Linux_for_Tegra/rootfs/lib/firmware/qca
	sudo cp -rv QCA9377_BT/qca/rampatch_usb_00000302.bin Linux_for_Tegra/rootfs/lib/firmware/qc
	rm -rf QCA9377_WIFI
	rm -rf QCA9377_BT

	# copy change boot config
	cd Linux_for_Tegra/rootfs/boot/extlinux/
	# close quiet for more dmesg
	sudo sed -i 's/APPEND \${cbootargs} quiet/APPEND \${cbootargs}/' extlinux.conf
	if [[ $OPTION -eq 1 ]];then
		sudo sed -i '10i \ \ \ \ \ \ FDT /boot/tegra194-p3668-tek3-nvjetson-a1.dtb' extlinux.conf
	elif [[ $OPTION -eq 2 ]];then
		sudo sed -i '10i \ \ \ \ \ \ FDT /boot/tegra210-tek3-nvjetson-a1.dtb' extlinux.conf
	else
		sudo sed -i 's|LINUX /boot/Image|LINUX /boot/Image_24-cam|' extlinux.conf
		sudo sed -i '10i \ \ \ \ \ \ FDT /boot/tegra194-p3668-tek8-nx210v-a1-24-cam.dtb' extlinux.conf
		sudo sed -i '13i \ \ \ \ \ \ APPEND ${cbootargs}' extlinux.conf
		sudo sed -i '13i \ \ \ \ \ \ FDT /boot/tegra194-p3668-tek8-nx210v-a1.dtb' extlinux.conf
		sudo sed -i '13i \ \ \ \ \ \ INITRD /boot/initrd' extlinux.conf
		sudo sed -i '13i \ \ \ \ \ \ LINUX /boot/Image' extlinux.conf
		sudo sed -i '13i \ \ \ \ \ \ MENU LABEL secondary kernel' extlinux.conf
		sudo sed -i '13i LABEL secondary' extlinux.conf
	fi
	cd ${CUR_DIR}

	# create new demo_image
	cd Linux_for_Tegra/
	if [[ $OPTION -eq 2 ]];then
		sudo ./flash.sh --no-flash jetson-nano-devkit-emmc mmcblk0p1
	else
		sudo ./flash.sh --no-flash jetson-xavier-nx-devkit-emmc mmcblk0p1
	fi
	cd ${CUR_DIR}
	echo -ne "done\n"
}

explain_options() {
	echo -e "******************************************"
	echo -e "All Operations."
	echo -e "******************************************\n"
	echo -e "1. TEK3-NVJETSON with Jetson Xavier Nx\n"
	echo -e "2. TEK3-NVJETSON with Jetson Nano\n"
	echo -e "3. TEK8-NX210V with Jetson Xavier Nx\n"
}

ask_for_option() {
	while true;
	do
		echo -en "Enter your choise:" && read -s -n1 OPTION
		echo ${OPTION}|grep -Poi "\d" > /dev/null
		if [[ $? -eq 0 ]];then
			break
		fi
		echo -e "\nPlease enter 1~3\n"
	done
	return ${OPTION}
}

check_option() {
	echo -e "\n\n"
	case "$1" in
	1)  echo -ne "1. TEK3-NVJETSON with Jetson Xavier Nx\n"
	    ;;
	2)  echo -ne "2. TEK3-NVJETSON with Jetson Nano\n"
	    ;;
	3)  echo -ne "3. TEK8-NX210V with Jetson Xavier Nx\n"
	    ;;
	*)  SKIP=1
	esac

	if [[ ${SKIP} -eq 1 ]];then
		echo -e "Wrong input!!\n"
		SKIP=0
		return 1
	fi

	echo -e "Is that your choise?? [Y/N]" && read -s -n1 YESORNO
	echo -e "\n"
	if [ "${YESORNO}" = "Y" ] || [ "${YESORNO}" = "y" ];then
		return 0
	else
		return 1
	fi
}

do_job () {
	CUR_DIR="$(pwd)/"
	get_nvidia_jetpack
	run_nvidia_script_and_sync_code

	sync_tn_source_code
	create_gcc_tool_chain

	create_kernel_compile_script
	if [[ $OPTION -eq 3 ]];then
		compile_kernel_for_24_cam
	fi
	compile_kernel

	if [[ $OPTION -eq 2 ]];then
		create_u-boot_compile_script
		compile_u-boot
	fi

	create_demo_image
	echo -ne "\n### Finish\n"
}


### Script start from here

if [ "$(id -u)" = "0" ]; then
	echo "This script can not be run as root"
	exit 1
fi

WRONG_OPTION=1
while [[ ${WRONG_OPTION} -eq 1 ]];
do
	explain_options
	ask_for_option
	OPTION=$?

	check_option ${OPTION}

	RET=$?
	if [[ $RET -eq 0 ]];then
		WRONG_OPTION=0
	else
		WRONG_OPTION=1
	fi
done

# install build require package
echo -ne "####install build require package\n"
sudo apt-get update -y
sudo apt-get install -y qemu-user-static bc kmod flex
sudo apt-get install -y gawk wget git git-core diffstat unzip texinfo gcc-multilib build-essential \
chrpath socat cpio python python3 python3-pip python3-pexpect \
python3-git python3-jinja2 libegl1-mesa pylint3 rsync bc bison \
xz-utils debianutils iputils-ping libsdl1.2-dev xterm \
language-pack-en coreutils texi2html file docbook-utils \
python-pysqlite2 help2man desktop-file-utils \
libgl1-mesa-dev libglu1-mesa-dev mercurial autoconf automake \
groff curl lzop asciidoc u-boot-tools libreoffice-writer \
sshpass ssh-askpass zip xz-utils kpartx vim screen

do_job
