---
title: ubuntu用kvm启动虚拟机搭建调试环境
sticky: false
comments: true
toc: true
toc_number: true
mathjax: false
highlight_shrink: false
aside: true
copyright: false
date: 2023-07-10 12:00:00
updated:
tags: tools
categories:
keywords: tools
description:
cover: 2.png
top_img: /media/top_img.jpg
copyright_author:
copyright_author_href:
copyright_url:
copyright_info:
---

1. 查看系统是否支持硬件加速
```bash
sudo apt install -y cpu-checker
$(kvm-ok)
```

一般物理机在物理机上执行都是支持硬件加速
![](1.png)

下载kvm组件
```BASH
sudo apt install -y qemu qemu-kvm libvirt-daemon-system libvirt-clients virt-manager virtinst bridge-utils
```

## 下载系统iso镜像文件
- 国内下载源

```
### 清华源 ubuntu-release 中存放的为系统镜像
https://mirrors.tuna.tsinghua.edu.cn/
https://mirrors.tuna.tsinghua.edu.cn/ubuntu-releases/

### 阿里源 
https://mirrors.aliyun.com/oldubuntu-releases/
```

## 使用virsh 虚拟机管理工具启动虚拟机

```bash
#!/bin/bash
#

imgpath=/ubuntu18-04.06.img
isopath=/ubuntu-18.04.06-server-amd64.iso
vmname=ubuntu18.04.04-guest

rm -f $imgpath
qemu-img create -f raw -o size=300G $imgpath
virt-install -n $vmname\
    --memory 8192\
    --vcpus 8\
    --cdrom $isopath\
    --os-variant ubuntu18.04\
    --disk $imgpath\
    --console pty,target_type=serial \
    --graphics vnc,port=5900,listen=0.0.0.0 \
    --video qxl\
    --network bridge=virbr0
    # --network bridge=br0
```

## 如果启动虚拟机报错

```bash

Formatting './diskimages/win11.img', fmt=raw size=322122547200
WARNING  /home/kali/ricardo/kvm/iso/Win11_23H2_English_x64v2.iso may not be accessible by the hypervisor. You will need to grant the 'libvirt-qemu' user earch permissions for the following directories: ['/home/kali']
WARNING  /home/kali/ricardo/kvm/diskimages/win11.img may not be accessible by the hypervisor. You will need to grant the 'libvirt-qemu' user search permissions for the following directories: ['/home/kali']
WARNING  /home/kali/ricardo/kvm/iso/Win11_23H2_English_x64v2.iso may not be accessible by the hypervisor. You will need to grant the 'libvirt-qemu' user search permissions for the following directories: ['/home/kali']

Starting install...
ERROR    internal error: process exited while connecting to monitor: 2023-12-26T16:29:50.396858Z qemu-system-x86_64: -blockdev {"driver":"file","filename":"/home/kali/ricardo/kvm/diskimages/win11.img","node-name":"libvirt-2-storage","auto-read-only":true,"discard":"unmap"}: Could not open '/home/kali/ricardo/kvm/diskimages/win11.img': Permission denied
Domain installation does not appear to have been successful.
If it was, you can restart your domain by running:
  virsh --connect qemu:///system start win11
otherwise, please restart your installation.

.img', fmt=raw size=322122547200
WARNING  /home/kali/ricardo/kvm/iso/Win11_23H2_English_x64v2.iso may not be accessible by the hypervisor. You will need to grant the 'libvirt-qemu' user search permissions for the following directories: ['/home/kali']
WARNING  /home/kali/ricardo/kvm/diskimages/win11.img may not be accessible by the hypervisor. You will need to grant the 'libvirt-qemu' user search permissions for the following directories: ['/home/kali']
WARNING  /home/kali/ricardo/kvm/iso/Win11_23H2_English_x64v2.iso may not be accessible by the hypervisor. You will need to grant the 'libvirt-qemu' user search permissions for the following directories: ['/home/kali']

Starting install...
ERROR    internal error: process exited while connecting to monitor: 2023-12-26T16:29:50.396858Z qemu-system-x86_64: -blockdev {"driver":"file","filename":"/home/kali/ricardo/kvm/diskimages/win11.img","node-name":"libvirt-2-storage","auto-read-only":true,"discard":"unmap"}: Could not open '/home/kali/ricardo/kvm/diskimages/win11.img': Permission denied
Domain installation does not appear to have been successful.
If it was, you can restart your domain by running:
  virsh --connect qemu:///system start win11
otherwise, please restart your installation.

```

changing /etc/libvirt/qemu.conf file
```bash
#       user = "100"    # A user named "100" or a user with uid=100
#


###  
# cancel this  "#"
###
# user = "root"                                                                

# The group for QEMU processes run by the system instance. It can be
# specified in a similar way to user.


###  
# cancel this  "#"
###
# group = "root"

# Whether libvirt should dynamically change file ownership
# to match the configured user/group above. Defaults to 1.
# Set to 0 to disable file ownership changes.
#dynamic_ownership = 1

```


启动后通过vnc连接目标虚拟机，然后安装目标操作系统，安装完成后会自动关机，然后进入宿主机执行命令启动目标虚拟机

```bash
### 列出所有虚拟机（包括未启动的虚拟机）
virsh list --all 

### 启动虚拟机
virsh start [guest-name]
```

## 进入虚拟机后安装ssh服务

```bash
sudo apt update 
sudo apt upgrade
sudo apt install -y openssh-server 

### 查看ssh服务状态，如果有 sshd，服务正常
sudo ps -e | grep ssh

### 启动 ssh 服务
sudo service ssh start 

### 停止 ssh 服务
sudo service ssh stop

### 重启 ssh 服务
sudo service ssh restart

### 安装网络工具包  ifconfig等命令
sudo apt install -y net-tools

### 查看主机 ip 地址
ip addr 
ifconfig

```

编辑网络创建网桥 vim   /etc/netplan/01-netcfg.yaml

```bash
network:
  version: 2
  renderer: networkd
  ethernets:
    eno1:
      dhcp4: no
    eno2:
      dhcp4: no
      # addresses: [10.1.36.45/23]
      # nameservers:
      #   addresses: [114.114.114.114]
  bridges:
    br0:
      interfaces: [eno2]
      addresses: [10.1.36.45/23]
      gateway4: 10.1.37.254
      nameservers:
        addresses: [114.114.114.114]
```

在host中设置端口转发规则，因为是NAT模式，所以其他机器如果想要远程连接虚拟机，则需要在host中设置端口转发:
```bash
#!/bin/bash

set -o errexit

function enable_forward {
    echo setup_forward_port
    # execute once
    KVM_ADAPTER_NAME="virbr0"
    KVM_SUBNET="192.168.122.0/24"


    WAN_ADAPTER_NAME="eno2"
    # allow virtual adapter to accept packets from outside the host
    iptables -I FORWARD -i $WAN_ADAPTER_NAME -o $KVM_ADAPTER_NAME -d $KVM_SUBNET -j ACCEPT
    iptables -I FORWARD -i $KVM_ADAPTER_NAME -o $WAN_ADAPTER_NAME -s $KVM_SUBNET -j ACCEPT

    #WAN_ADAPTER_NAME="cni0"
    ## allow virtual adapter to accept packets from host k8s container
    ## forward change destination, but not change source interface
    #iptables -I FORWARD -i $WAN_ADAPTER_NAME -o $KVM_ADAPTER_NAME -d $KVM_SUBNET -j ACCEPT
    #iptables -I FORWARD -i $KVM_ADAPTER_NAME -o $WAN_ADAPTER_NAME -s $KVM_SUBNET -j ACCEPT
    ## iptables -I FORWARD -s 10.244.0.0/16 -d $KVM_SUBNET -j ACCEPT

    #WAN_ADAPTER_NAME="docker0"
    ## allow virtual adapter to accept packets from host docker container
    ## forward change destination, but not change source interface
    #iptables -I FORWARD -i $WAN_ADAPTER_NAME -o $KVM_ADAPTER_NAME -d $KVM_SUBNET -j ACCEPT
    #iptables -I FORWARD -i $KVM_ADAPTER_NAME -o $WAN_ADAPTER_NAME -s $KVM_SUBNET -j ACCEPT
}



function setup_forward_port {
    KVM_ADAPTER_HOST=$1
    WAN_PORT=$2
    KVM_PORT=$3

    echo setup_forward_port $KVM_ADAPTER_HOST

    adapter_hosts=("10.1.36.45")
    for WAN_ADAPTER_HOST in "${adapter_hosts[@]}"
    do
    ¦   echo "Forwarding wan_adapter_hosts: $WAN_ADAPTER_HOST"
    ¦   # forward ports from outer-host to guest
    ¦   iptables -t nat -I PREROUTING -d $WAN_ADAPTER_HOST -p tcp --dport $WAN_PORT -j  DNAT --to-destination $KVM_ADAPTER_HOST:$KVM_PORT
    ¦   # forward ports from inner-host to guest
    ¦   iptables -t nat -I OUTPUT -d $WAN_ADAPTER_HOST -p tcp --dport $WAN_PORT -j DNAT --to-destination $KVM_ADAPTER_HOST:$KVM_PORT
    done
}

function list_forward {
    KVM_ADAPTER_HOST=$1
    echo list_forward $KVM_ADAPTER_HOST
    echo "Processing chain: PREROUTING"
    iptables --line-numbers --list PREROUTING -t nat | awk -F: '$3=="'$KVM_ADAPTER_HOST'"''{print}'
    echo "Processing chain: OUTPUT"
    iptables --line-numbers --list OUTPUT -t nat | awk -F: '$3=="'$KVM_ADAPTER_HOST'"''{print}'
}

function list_forward_port {
    KVM_ADAPTER_HOST=$1
    KVM_PORT=$2
    echo list_forward_port $KVM_ADAPTER_HOST
    iptables --line-numbers --list PREROUTING -t nat | awk '$9=="to:'$KVM_ADAPTER_HOST':'$KVM_PORT'" {print}'
    iptables --line-numbers --list OUTPUT -t nat | awk '$9=="to:'$KVM_ADAPTER_HOST':'$KVM_PORT'" {print}'
    # iptables -t nat -nvL OUTPUT
}

function clear_forward_port {
    KVM_ADAPTER_HOST=$1
    KVM_PORT=$2
    echo clear_forward_port $KVM_ADAPTER_HOST

    iptables_chains=("PREROUTING" "OUTPUT")
    for chain in "${iptables_chains[@]}"
    do
    ¦   echo "Processing chain: $chain"
    ¦   for line_num in $(iptables --line-numbers --list $chain -t nat | awk '$9=="to:'$KVM_ADAPTER_HOST':'$KVM_PORT'" {print $1}')
    ¦   do
    ¦   ¦   # You can't just delete lines here because the line numbers get reordered
    ¦   ¦   # after deletion, which would mean after the first one you're deleting the
    ¦   ¦   # wrong line. Instead put them in a reverse ordered list.
    ¦   ¦   LINES="$line_num $LINES"
    ¦   done

    ¦   # Delete the lines, last to first.
    ¦   for line in $LINES
    ¦   do
    ¦   ¦   # echo $line
    ¦   ¦   iptables -t nat -D $chain $line
    ¦   done
    ¦   unset LINES
    done

}

enable_forward


# setup iptables
# ubuntu desktop
KVM_ADAPTER_HOST="192.168.122.128"
setup_forward_port $KVM_ADAPTER_HOST 22622 22 # ssh

# ubuntu server
# KVM_ADAPTER_HOST="192.168.122.121"
# setup_forward_port $KVM_ADAPTER_HOST 22122 22 # ssh

list_forward $KVM_ADAPTER_HOST


#KVM_ADAPTER_HOST="192.168.122.79"
#clear_forward_port $KVM_ADAPTER_HOST 22 # ssh
```
