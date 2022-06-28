#!/bin/bash

CUR_DIR="$(pwd)/"
NV_TAG="tegra-l4t-r32.7.1"
TAG="pre-release"
BRANCH="tn_l4t-r32.7.1_kernel-4.9"

download_tn_jetpack() {
	echo -ne "\n### Get TN-Jetpack\n"
	if [[ $OPTION -eq 1 ]];then
		echo -ne "Download TN-Jetpack with Xavier-NX(TEK3-NVJETSON)\n"
		wget --continue https://ftp.technexion.com/development_resources/nvidia/jetpack/Xavier-NX/TEK3-NVJETSON/jetpack_xavier-nx_tek3-nvjetson_ubuntu-18.04_pre-release_20220606.tgz --tries=10 -O jetpack.tgz
	elif [[ $OPTION -eq 2 ]];then
		echo -ne "Download TN-Jetpack with Nano(TEK3-NVJETSON)\n"
		wget --continue https://ftp.technexion.com/development_resources/nvidia/jetpack/Nano/TEK3-NVJETSON/jetpack_nano_tek3-nvjetson_ubuntu-18.04_pre-release_20220602.tgz --tries=10 -O jetpack.tgz
	else
		echo -ne "Download TN-Jetpack with Xavier-NX(TEK8-NVJETSON)\n"
		wget --continue https://ftp.technexion.com/development_resources/nvidia/jetpack/Xavier-NX/TEK8-NVJETSON/jetpack_xavier-nx_tek8-nvjetson_ubuntu-18.04_pre-release_20220606.tgz --tries=10 -O jetpack.tgz
	fi
	tar zxvf jetpack.tgz
	echo -ne "done\n"
}

explain_options() {
	echo -e "******************************************"
	echo -e "All Operations."
	echo -e "******************************************\n"
	echo -e "1. TEK3-NVJETSON with Jetson Xavier Nx\n"
	echo -e "2. TEK3-NVJETSON with Jetson Nano\n"
	echo -e "3. TEK8-NVJETSON with Jetson Xavier Nx\n"
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
	3)  echo -ne "3. TEK8-NVJETSON with Jetson Xavier Nx\n"
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

create_gcc_tool_chain () {
	echo -ne "\n### Download gcc tool chain\n"
	cd Linux_for_Tegra/sources/kernel/
	mkdir gcc_tool_chain
	cd gcc_tool_chain/
	GCC_TOOL_CHAIN="$(pwd)/"
	wget https://releases.linaro.org/components/toolchain/binaries/7.4-2019.02/aarch64-linux-gnu/gcc-linaro-7.4.1-2019.02-x86_64_aarch64-linux-gnu.tar.xz --tries=10
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

### Script start from here

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

download_tn_jetpack

echo -ne "\n### Clone nvidia source code\n"
cd Linux_for_Tegra/
./source_sync.sh -t ${NV_TAG}
cd ${CUR_DIR}
echo -ne "done\n"

echo -ne "\n### Clone source code from Technexion github\n"
echo -ne "# kernel\n"
cd Linux_for_Tegra/sources/kernel/kernel-4.9/
git remote add tn-github git@github.com:TechNexion-Vision/TEV-Jetson_kernel.git
git pull tn-github
git checkout $BRANCH
git reset --hard $TAG
cd ${CUR_DIR}
echo -ne "# dts\n"
if [[ $OPTION -eq 2 ]];then
	cd Linux_for_Tegra/sources/hardware/nvidia/platform/t210/porg/
	git remote add tn-github git@github.com:TechNexion-Vision/TEV-JetsonNano_device-tree.git
else
	cd Linux_for_Tegra/sources/hardware/nvidia/platform/t19x/jakku/kernel-dts/
	git remote add tn-github git@github.com:TechNexion-Vision/TEV-JetsonXavier-NX_device-tree.git
fi
git pull tn-github
git checkout $BRANCH
git reset --hard $TAG
cd ${CUR_DIR}
echo -ne "# technexion camera drivers\n"
cd Linux_for_Tegra/sources/kernel/
git clone git@github.com:TechNexion-Vision/TEV-Jetson_Camera_driver.git technexion
cd technexion
git checkout $BRANCH
git reset --hard $TAG
cd ${CUR_DIR}
echo -ne "# technexion pinmux file(xlsm)\n"
cd Linux_for_Tegra/sources/
if [[ $OPTION -eq 1 ]];then
	git clone git@github.com:TechNexion-Vision/TEV-JetsonXavier-NX_pinmux.git TEK3-NVJETSON_Xavier-NX_pinmux
	cd TEK3-NVJETSON_Xavier-NX_pinmux
	git checkout ${BRANCH}_TEK3-NVJETSON-a1
	git reset --hard ${TAG}_TEK3-NVJETSON-a1
elif [[ $OPTION -eq 2 ]];then
	git clone git@github.com:TechNexion-Vision/TEV-JetsonNano_pinmux.git TEK3-NVJETSON_Nano_pinmux
	cd TEK3-NVJETSON_Nano_pinmux
	git checkout ${BRANCH}_TEK3-NVJETSON-a1
	git reset --hard ${TAG}_TEK3-NVJETSON-a1
elif [[ $OPTION -eq 3 ]];then
	git clone git@github.com:TechNexion-Vision/TEV-JetsonXavier-NX_pinmux.git TEK8-NVJETSON_Xavier-NX_pinmux
	cd TEK8-NVJETSON_Xavier-NX_pinmux
	git checkout ${BRANCH}_TEK8-NVJETSON-a1
	git reset --hard ${TAG}_TEK8-NVJETSON-a1
fi
cd ${CUR_DIR}
if [[ $OPTION -eq 2 ]];then
	echo -ne "# u-boot\n"
	cd Linux_for_Tegra/sources/u-boot/
	git remote add tn-github git@github.com:TechNexion-Vision/TEV-JetsonNano_u-boot.git
	git pull tn-github
	git checkout ${BRANCH}_TEK3-NVJETSON-a1
	git reset --hard ${TAG}_TEK3-NVJETSON-a1
	cd ${CUR_DIR}
fi
echo -ne "done\n"

create_gcc_tool_chain
create_kernel_compile_script

if [[ $OPTION -eq 2 ]];then
	create_u-boot_compile_script
fi

echo -ne "\n### Finish\n"
