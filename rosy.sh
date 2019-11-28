#!/usr/bin/env bash

# Copyright (C) 2019 Shadow Of Mordor (energyspear17@xda)
# SPDX-License-Identifier: GPL-3.0-only

# Script used to build Shadow Kernel

# Kernel Config Variables

KERNEL_DIR=${PWD}
KERNEL="Rosy"
BUILD_USER="sukrut4778"
BUILD_HOST="Pikachu"
DEVICE=$(echo ${PWD##*/} | cut -d'-' -f2)
VERSION=$(git branch | grep \* | cut -d ' ' -f2)
ARCH="arm64"
CROSS_COMPILE="/home/${USER}/toolchain/gcc-linaro-7.4.1/bin/aarch64-linux-gnu-"
CROSS_COMPILE_ARM32="/home/${USER}/toolchain/gcc-linaro-7.4.1-32/bin/arm-linux-gnueabi-"
CC="/home/${USER}/toolchain/clang-9.0.8/bin/clang"
CLANG_TRIPLE="aarch64-linux-gnu-"
CCACHE_DIR="~/.ccache"
OUT="out"

# Color configs

yellow='\033[0;33m'
white='\033[0m'
red='\033[0;31m'
gre='\e[0;32m'
blue='\033[0;34m'
cyan='\033[0;36m'

# Build configs

zimage="${KERNEL_DIR}/out/arch/arm64/boot/Image"
time=$(date +"%d-%m-%y-%T")
date=$(date +"%d-%m-%y")
build_type="gcc"
v=$(grep "CONFIG_LOCALVERSION=" "${KERNEL_DIR}/arch/arm64/configs/pikachu_defconfig" | cut -d- -f3- | cut -d\" -f1)
zip_name="${KERNEL,,}-${VERSION}-v${v}-${date}.zip"

function build() {

if [ "$1" = "gcc" ]; then
    echo -e "$blue Building Kernel with gcc... \n $white"
    export KBUILD_BUILD_HOST="${BUILD_HOST}"
    export KBUILD_BUILD_USER="${BUILD_USER}"
    export ARCH="${ARCH}"
    export CROSS_COMPILE="${CROSS_COMPILE}"
    export CROSS_COMPILE_ARM32="${CROSS_COMPILE_ARM32}"
    export USE_CCACHE=1
    export CCACHE_DIR="${CCACHE_DIR}"
    ccache -M 50G
    make O="${OUT}" "pikachu_defconfig"
    make O="${OUT}" -j$(nproc --all)
else
    echo -e "$yellow Building Kernel with clang... \n $white"
    export KBUILD_BUILD_HOST="${BUILD_HOST}"
    export KBUILD_BUILD_USER="${BUILD_USER}"
    export USE_CCACHE=1
    export CCACHE_DIR="${CCACHE_DIR}"
    ccache -M 50G
    make O="${OUT}" ARCH="${ARCH}" "pikachu_defconfig"
    make -j$(nproc --all) O="${OUT}" \
                      ARCH="${ARCH}" \
                      CC="${CC}" \
                      CLANG_TRIPLE="${CLANG_TRIPLE}" \
		      CROSS_COMPILE_ARM32="${CROSS_COMPILE_ARM32}" \
                      CROSS_COMPILE="${CROSS_COMPILE}"
fi
  spin[0]="$gre-"
  spin[1]="\\"
  spin[2]="|"
  spin[3]="/$nc"

  echo -ne "$yellow [Please wait...] ${spin[0]}$nc"
  while kill -0 $pid &>/dev/null
  do
    for i in "${spin[@]}"
    do
          echo -ne "\b$i"
          sleep 0.1
    done
  done
if ! [ -a ${zimage} ]; then
    echo -e "$red << Failed to compile zImage, check log and fix the errors first >>$white"
    exit 1
fi
echo -e "$yellow\n Build successful !\n $white"
End=$(date +"%s")
Diff=$(($End - $Start))
echo -e "$gre << Build completed in $(($Diff / 60)) minutes and $(($Diff % 60)) seconds >> \n $white"        
}

function clean() {

echo -e "$blue Cleaning... \n$white"
make O=$OUT clean
make O=$OUT mrproper
make clean && make mrproper
rm ${KERNEL_DIR}/out/arch/arm64/boot/Image

}

function makezip() {
echo -e "$yellow\n Cloning Zip if folder not exist... \n $white"
git clone https://github.com/Sukrut4778/zip.git zip/
echo -e "$blue\n Generating flashable zip now... \n $white"
cp ${KERNEL_DIR}/out/arch/arm64/boot/Image.gz-dtb ${KERNEL_DIR}/zip
cd zip/
rm *.zip modules/patchholder patch/patchholder ramdisk/patchholder
zip -r $zip_name *
cd ${KERNEL_DIR}
}

function main() {

echo -e ""

if [ "$1" = "" ]; then
    echo -e "$blue\n 1.Build $KERNEL\n$gre\n 2.Make Zip\n$yellow\n 3.Clean Source\n$red\n 4.Exit\n$white"
    echo -n " Enter your choice:"
    read ch

    case $ch in
        1)
            read -r -p "Do you want to compile with clang ? y/n :" CL_ANS
            if [ "$CL_ANS" = "y" ]; then
                build_type="clang"
            fi

            read -r -p "Do you want to make clean build ? y/n :" CL_ANS
            if [ "$CL_ANS" = "y" ]; then
            echo -e "$yellow Running make clean before compiling \n$white"
            clean
            fi
            Start=$(date +"%s")
            build $build_type
            read -r -p "Do you want to make flashable zip ? y/n :" ZIP
            if [ "$ZIP" = "y" ]; then
                makezip 
            fi
            ;;
        2)
            makezip
            ;;
        3)
            clean
            ;;
        *)
           exit 1
    esac
    
else
    case $1 in
        b)
            if [ "$2" = "" ]; then
                echo -e "$red << Please Specify clang or gcc... >>$white"
                exit 2
            fi
            read -r -p "Do you want to make clean build ? y/n :" CL_ANS
            if [ "$CL_ANS" = "y" ]; then
            echo -e "$yellow Running make clean before compiling \n$white"
            clean
            fi
            Start=$(date +"%s")
            build $2
            if [ "$3" = "y" ]; then
                makezip $4
            fi
            ;;
        mc)
            makezip
            ;;
        c)
            clean
            ;;
        u)
            if [ "$2" = "" ]; then
                echo -e "$red << Please Specify telegram or gdrive (t/g/tg)... >>$white"
                exit 2
            fi
	    makezip $2
	    ;;
        *)
           echo -e "$red << Unknown argument passed... >>$white"
           exit 1
    esac

fi
}

main $1 $2 $3 $4
