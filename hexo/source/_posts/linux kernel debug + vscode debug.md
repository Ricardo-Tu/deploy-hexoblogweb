---
title: linux kernel debug + vscode debug
sticky: false
comments: true
toc: true
toc_number: true
mathjax: true
highlight_shrink: false
aside: true
copyright: false
date: 2023-06-13 12:00:00
updated:
tags: tools
categories:
keywords: tools
description:
cover: 1.png
top_img: /media/15.jpg
copyright_author:
copyright_author_href:
copyright_url:
copyright_info:
---

## 编译x86版本linux kerne
```bash
# 打开调试选项
make menuconfig
# 打开　kenel kacking -> compile-time checks and compiler options -> debug infomation -> rely on 
# the toolchain's implicit default DWARF version
# 保存退出，如果编译错误，执行　make clean  && make defconfig全部设置为默认选项，然后重新打开上面选项

make -j$(nproc)
# 编译成功后输出为 x86格式,文件为./arch/x86/boot/bzImage
# 其中当前目录下的 vmlinux 为gdb调试使用的符号文件
```

## 编译arm版本linux kernel
```bash
# 下载交叉编译工具链
sudo apt install gcc-arm-linux-gnueabihf
sudo apt install g++-arm-linux-gnueabihf

# uninstall 
sudo apt remove g++-arm-linux-gnueabihf

# 配置编译环境
make ARCH=arm defconfig
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- menuconfig

#编译
make -j$(nproc) ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-
```

## 编译risc-v版本linux kernel
```bash
# 下载编译依赖
sudo apt install autoconf automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev

# 下载　risc-v 交叉编译工具链源码
git clone --recursive https://github.com/riscv/riscv-tools.git

# 配置编译环境
make ARCH=riscv defconfig
make ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- menuconfig


#编译
make -j$(nproc) ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu-

```

### risc-v版本qemu调试需要另外添加固件,opensbi编译
```bash
# opensbi 是处于　M-mode
git clone https://github.com/riscv-software-src/opensbi.git
cd opensbi/
make -j$(nproc) CROSS_COMPILE=riscv64-linux-gnu- PLATFORM=generic

# 编译完成后输出文件位置
# build/platform/generic/firmware/fw_dynamic.bin
```

## 编译busybox命令集合和制作根文件系统
### 编译busybox命令集合
```bash
git clone https://github.com/mirror/busybox.git


# busybox提供了几种配置：
#	defconfig (缺省配置)、
#	allyesconfig（最大配置）、 
#	allnoconfig（最小配置），
# 	一般选择缺省配置即可

make allyesconfig　ARCH=x86_64
make allyesconfig　ARCH=arm 
make allyesconfig　ARCH=riscv 

make menuconfig
# 按下面选择，把busybox编译也静态二进制、不用共享库:
#	Settings -> Build Options -> [*] Build static binary (no shared libs)
###
# 或者　vim .config 　在里面添加上　CONFIG_STATIC=y


# 编译 x86
make -j$(nproc) ARCH=x86_64

# 编译　arm
make -j$(nproc) ARCH=arm 　CROSS_COMPILE=arm-linux-gnueabihf-

# 编译　risc-v
make -j$(nproc) ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu-


make install 
make install ARCH=arm   CROSS_COMPILE=riscv64-linux-gnu- 
make install ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- 

# 执行完之后在busybox目录下会出现 _install 文件夹
```

### 编译完成后构建根文件系统
```bash
cd _install
mkdir proc sys dev etc etc/init.d
touch etc/init.d/rcS
vim etc/init.d/rcS
```
rcS文件内容:
```bash
#!bin/sh 
mount -t proc none /proc 
mount -t sysfs none /sys 
/sbin/mdev -s
```
执行:
```bash
sudo mknod dev/console c 5 1 
sudo mknod dev/ram b 1 0

# 给 rcS 文件添加可执行属性
chmod a+x etc/init.d/rcS
find -print0 | cpio -0oH newc | gzip -9 > ../x86_64-rootfs.img
```

qemu-gdb运行脚本:
```bash
qemu-system-x86_64 \                                                      
    -kernel ./x86_64-bzImage \  
    -initrd ./x86_64-rootfs.img \        
    -m 4G \                   
    -nographic \         
    -append "root=/dev/ram rdinit=/sbin/init earlyprintk=serial,ttyS0 console=ttyS0 nokaslr" \   
    -S \     
    -s 
```
下断点在./init/main.c中的start_kernel函数
## 调试linux　kernel时候显示代码红线解决方案
```bash
# 在linux　kernel源码文件夹根目录下执行生成json命令
python ./linux-6.6.8/scripts/clang-tools/gen_compile_commands.py 
```
## vscode中launch.json文件内容
```bash
{
    // Use IntelliSense to learn about possible attributes.
    // Hover to view descriptions of existing attributes.
    // For more information, visit: https://go.microsoft.com/fwlink/?linkid=830387
    "version": "0.2.0",
    "configurations": [],
    "name": "qemu-kernel-gdb",
    "type": "cppdbg",
    "request": "launch",
    "miDebuggerServerAddress": "localhost:1234",
    "program": "${workspaceFolder}/vmlinux",
    "args": [],
    "stopAtEntry": false,
    "cwd": "${workspaceFolder}",
    "environment": [],
    "externalConsole": false,
    "logging": {
        "engineLogging": false
    },
    "MIMode": "gdb"
}
```
