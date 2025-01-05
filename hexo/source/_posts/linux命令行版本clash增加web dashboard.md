---
title: linux命令行版本clash增加web dashboard
sticky: false
comments: true
toc: true
toc_number: true
mathjax: true
highlight_shrink: false
aside: true
copyright: false
date: 2023-04-5 12:00:00
updated:
tags: tools
categories:
keywords: tools
description:
cover: 1.png
top_img: /media/top_img.jpg
copyright_author:
copyright_author_href:
copyright_url:
copyright_info:
---

## 命令行所添加web组件下载地址：
```
https://github.com/haishanh/yacd/
https://github.com/haishanh/yacd/releases

wget https://github.com/haishanh/yacd/releases/download/v0.3.7/yacd.tar.xz

## 教程地址
https://parrotsec-cn.org/t/linux-clash-dashboard/5169
```

## clash运行命令
```
sudo /home/ubuntu/zhonghui/vpn/clash -d /home/ubuntu/zhonghui/vpn/  -f /home/ubuntu/zhonghui/vpn/config.yaml
```

## 在下载yaml文件后在文件中添加密码和ui，修改外部controller地址为0.0.0.0
```yaml
port: 7890
socks-port: 7891
allow-lan: true
mode: Rule
log-level: info
secert: 123456         // 增加这一行, 如果你希望你的clash  web要密码访问可以在这块配置密码, 如果不需要直接注释掉即可
external-ui: dashboard // 增加这一行
external-controller: 0.0.0.0:9090
```

## ~/.bashrc.sh中添加
```bash
export http_proxy=http://127.0.0.1:7890
export https_proxy=http://127.0.0.1:7890
export ftp_proxy=http://127.0.0.1:7891   
```

## 网站中访问ui界面
```bash
http://101.43.169.63:9090/ui/#/proxies
```
