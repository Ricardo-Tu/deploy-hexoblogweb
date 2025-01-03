---
title: 逻辑分析仪的使用
sticky: false
comments: true
toc: true
toc_number: true
mathjax: false
highlight_shrink: false
aside: true
copyright: false
date: 2024-06-10 12:00:00
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

# 工具
esp32 逻辑分析仪

# 准备工作

使用vscode中的Platform IO插件build upload程序到esp32中，安装platfor IO工具有几个注意的点

    1.  不能使用系统python自带的python工具执行pip install platformio，这会导致vscode中打开失败，只有网页127.0.0.1:8008可以访问pio home

    2. 设置中搜索platformio-ide:custom path中编辑json文件，在里面添加系统环境变量中python的路径：


```bash
    "platformio-ide.customPATH": "C:\\Users\\zhonghui\\AppData\\Local\\Programs\\Python\\Python312\\Scripts"
```

# code

```c
#include <Arduino.h>
int flag = 0;

// 设置串口波特率
void setup()
{
  pinMode(32, OUTPUT);
  pinMode(33, OUTPUT);
  // while (!Serial)
  // {
  // ; // 等待串口连接
  // }
}

// 主循环
void loop()
{
  digitalWrite(32, HIGH);
  delay(1000); // 每隔一秒输出一次
  digitalWrite(32, LOW);
  if (flag == 0)
  {
    digitalWrite(33, LOW);
    flag = 1;
  }
  else
  {
    digitalWrite(33, HIGH);
    flag = 0;
  }
  delay(1000); // 每隔一秒输出一次
}
```

上面代码让32号引脚电平每秒跳变一次，33号引脚2秒跳变一次

引脚的编号要参考产品手册：
![](1.jpeg)

连接好之后，效果图如下:
![](2.png)

可以清晰的看到32号33号引脚电平变化