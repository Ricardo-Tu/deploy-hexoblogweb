---
title: Windows(IA-32e模式)系统调用
sticky: false
comments: true
toc: true
toc_number: true
mathjax: false
highlight_shrink: false
aside: true
copyright: false
date: 2021-11-06 12:00:01
updated:
tags: system
categories:
keywords: system-call calling-convention
description:
cover: 7.png
top_img: /media/top_img.jpg
copyright_author:
copyright_author_href:
copyright_url:
copyright_info:
---

# 一、本文主题

Windows NT是一个面向分层的操作系统，最底层是硬件，最高层使用户接口，Windows采用这种模式来保护内核不被应用程序错误的波及，操作系统核心运行在内核层(Ring 0 )，用户模式运行在应用层(Ring 3)。这只是操作系统分层的抽象概念。而本文旨在讨论Windows操作系统在IA-32e模式下从Ring3进入Ring0的部分具体实现过程，也会对比IA-32模式下的部分差异。本文IA-32e测试系统为Windows 10 2004。

# 二、系统调用

Windows操作系统通过任务门、陷阱门、中断门三种途径进入内核。其中任务门通过应用层执行syscall指令后，执行系统调用分发函数KiSystemCall64Shadow，这个函数的地址存放在IA32_LSTAR(0xc0000082)的MSR寄存器中。

![](1.png)

当我们从应用层调用一个API时，会通过应用层的ntdll进入内核，在执行syscall指令时，寄存器按照一些规则改变，本文举例介绍一些：

1. 将syscall下一条指令地址存放在rcx寄存器中

2. 将rip设置为IA32_LSTAR寄存器中的值

3. cs寄存器中Selector字段值设置为IA32_STAR(0xc0000081)寄存器中32位到47位的值与0xFFFC的值

4. SS寄存器Selector字段为IA32_STAR(0xc0000081)寄存器中32位到47位的值与0xFFFC再加8的值

所以在调用syscall指令之前，还需要一些准备工作，将函数在SSDT表中的索引号存放在rax寄存器中，将rcx的值放入r10寄存器中。

![](2.png)

首先我们在ntdll!NtOpenProcess处下一个断点，在KiSystemCall64Shadow函数内下第二个硬件断点(注意在KiSystemCall64Shadow下断点需要在swapgs指令后下断点，断点处理函数需要用内核堆栈，如果在swapgs处下断点，会卡死)。

首先在ntdll!NtOpenProcess中下断点，然后运行后windbg在NtOpenProcess中断下，然后在KiSystemCall64Shadow中下一个硬件断点。运行后在KiSytemCall64Shadow中断下。

![](3.png)

接着找到KeServiceDescriptorTable结构体指针，这是一个未公开的结构体，不过已经有人将这个结构体逆出来，结构体如下:

```c
typedef struct _KSERVICE_TABLE_DESCRIPTOR

{

    PVOID  Tablebase;

    PULONG   ServiceCountBase;

    ULONG64  ServiceNumber;

    PVOID ParameterNumer;

}KSERVICE_TABLE_SECRIPTOR,*PKSERVICE_TABLE_DESCRIPTOR;
```

![](4.png)

在 lea r10, KeServiceDescriptorTable处下一个断点，动态调试观察代码可了解r11和r10值的关系。

![](5.png)

而这两张表的关系如图所示：

![](6.png)

从图中的关系我们不难理解取SSDT表中函数地址的过程：

![](7.png)

在获得函数地址后，接着便是拷贝参数，执行函数。最后调用sysret，sysret指令和syscall指令情况相反，恢复用户层堆栈，将返回地址放入rcx，执行后会将rcx的值设为rip。

# 三、异常

异常分为中断、错误、陷阱。

在处理器执行一条指令时，有可能会陷入异常。比如除0错误。异常一般分为错误和陷阱。比如缺页异常，当页面从pagefile写入物理内存，挂上物理页面之后，会从原指令处执行。比如syscall这样的指令，属于陷阱，返回后从下一条指令处开始执行。在Intel的x64中，定义了一个表项为256的IDT表。而中断和异常的区别为，中断和陷阱的区别在于，中断处理函数执行时会关中断(清IF标记位)，而陷阱则不会清IF标志位。中断门描述符各部分如下。

![](8.png)

DPL为触发中段权限检查，如处于Ring3，只能触发DPL为3的中断，而Ring0则可以触发DPL为0或者3的中断。

下图为Windows 10 2004中断的部分中断门描述符和函数地址。

![](9.png)

比如第0项，门描述符为6b628e00`0010a100 00000000`fffff801，函数地址为0xfffff8016b62a100,P为1，DPL为0(这个中断3环不能触发)，TYPE为6，IST为0(IST为0，说明使用的为IST0栈，这个值需要在GDT表所指向的TSS中索引)，在x64中intel芯片手册中写到Segmentation is not used，在GDT表中也只有一个TSS段。

![](10.png)

第2项，门描述符为6b628e03`0010a240 00000000`fffff801，函数地址为0xfffff8016b62a240，P为1，DPL为0，TYPE为6,IST为3，这个不可屏蔽中断使用的栈指针为0xFFFFF8016E7567D0,为上图中IST3的数值，寻找这个表，首先读取tr寄存器的值，其大小为TSS段描述符在GDT表中的偏移，TSS段描述符有128位，解析得到地址，这个地址就为上图地址。

    本文参考： Intel® 64 and IA-32 Architectures Software Developer’s Manual

**学习过程中还有很多不足，还望朋友们指正！**
