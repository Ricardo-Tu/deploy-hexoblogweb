---
title: x86指令集和arm指令集部分对比
sticky: false
comments: true
toc: true
toc_number: true
mathjax: false
highlight_shrink: false
aside: true
copyright: false
date: 2023-12-01 12:00:09
updated:
tags: start
categories:
keywords:
description:
cover: 7.png
top_img: /media/19.jpg
copyright_author:
copyright_author_href:
copyright_url:
copyright_info:
---

# 一、x86 ISA

1. 指令组成

![](1.png)

由图一可知一条x86的指令可分为Instruction Prefixes、Opcode、Mod R/M、 SIB 、Displacement、Immediate这六个部分，其中Opcode为必选部分，其他都为可选部分。

# 二、指令各部分解析

1. Instruction Prefixes（可选部分）
指令前缀这部分被划分为Lock和重复前缀、段前缀、操作数长度修饰前缀、地址长度修饰前缀四组。

   - Lock前缀：在destination oprand为内存操作时时，在部分特定的指令前加上lock前缀保证为原子操作，若非这部分特定指令，执行会抛#UD异常

   - 循环前缀：在movs指令前添加rep 、repnz循环前缀

    ```bash
        F0:8300 02    lock add dword ptr ds:[eax],2 
        8300 02        add dword ptr ds:[eax],2 
        F2:A4        repne movsb  
        F3:A4        rep movsb  
    ```

   - 段前缀：用作内存访问权限控制

    ```bash
        2E:C700 01000000     mov dword ptr cs:[eax],1
        3E:C701 01000000     mov dword ptr ds:[ecx],1
        26:C700 01000000     mov dword ptr es:[eax],1
        36:C700 01000000     mov dword ptr ss:[eax],1
        64:C700 01000000     mov dword ptr fs:[eax],1
        65:C700 01000000     mov dword ptr gs:[eax],1
    ```

   - 操作数长度修饰前缀：用来修饰操作数长度

   ```bash
    C700 01000000     mov dword ptr ds:[eax],1 
    66:C700 0100     mov word ptr ds:[eax],1 
   ```

   - 地址长度修饰前缀

   ```bash
       2E:C700 01000000 mov dword ptr cs:[rax],1
       2E67:C700 01000000 mov dword ptr cs:[eax],1 
   ```

2. Opcode （必选部分）

    主操作码可能是一字节两字节三字节长度。这个字段会确定是否存在Mod R/M和SIB字段。

3. Mod R/M

    这个部分如果存在，则这个部分的长度为一个字节。这个部分分为mod、reg、r/m三个部分

    ![](2.png)

    ```bash
    mod： 指明操作码中的操作数表示寄存器还是内存，11表示内存，其余表示寄存器
    ​​​​reg：标记通用寄存器
    r/m：如果为100则无作用，其余的情况下和REX PREFIX共同组合表示取址的格式
    ```

    取址方式，若为内存寻址则需要SIB字段辅助

4. SIB

    如果modR/M的r/m部分为100，则存在SIB Byte部分，这部分分为scale、index、base三部分。

    ![](3.png)

    Scale和index的三个字节和REX PREFIX的1号位（X）组合而成的4位、以及modR/M和REX PREFIX的2号位（R）组合而成的4位这三部分共同确定了取值的方式，

    ![](4.png)

5. Displacement

    这部分字段为地址移位长度。长度可以为1个字节到8个字节，是可选部分。

6. Immediate

    这个部分为表示的为指令中的立即数，长度可以为1个字节到8个字节，是可选部分。

# 二、ARM ISA

ARM的CPU有arm和thumb两种运行状态，CPU在不同的状态下执行不同的指令集，通过PSR寄存器的T标志位控制模式，T标志位为0表示arm模式，arm指令长度为4byte；为1表示thumb模式，thumb模式下指令的长度为4byte或2byte。

由于ARM指令是2字节对齐，所以内存的最低位一定为偶数，在使用LDR和BX指令进行分支跳转和。CPU在运行时候进行分支跳转和模式切换的方式主要有两种，一种是利用LDR指令将内存中的地址写入PC寄存器，跳转地址的最低位（lsb）为0切换为arm模式，最低为为1切换为thumb模式。

接下来本文会枚举一些x86指令集和arm指令集的区别：

1. 指令长度区别
    x86指令为变长指令，arm指令的长度为2byte或者4byte，所以arm指令中的操作数都小于32字节

    例如 mov指令给寄存器赋值一个32位长度数字：

    ```bash
    X86：B8 44332211   mov eax,11223344
    ```

    这是在x86的机器上，在32位模式下给一个32位寄存器赋一个32位值的硬编码，B8为opcode，后面为操作数，指令长度为5个字节:

    ```bash
    Arm:   44 03 03 E3         MOVW  R0, #0x3344
    
        22 01 41 E3         MOVT  R0, #0x1122
    ```

    这是arm模式下的一种实现方式：

    第一条指令硬编码为:

    ```bash
    1110  00110    0  00  0011   0000   001101000100
    ```

    第一条指令的编码格式是:

    ![](5.png)

    其中cond为条件判断，在arm模式下一般指令都会有条件判断，thumb模式编码一般没有添加执行判断条件，这条指令中cond为1110为无条件执行，imm4为0011 è 0x3 Rd为0表示r0寄存器，imm12为001101000100 è0x344 组合而成imm16 = imm4:imm12 为0x3344

    第二条指令硬编码为

    ```bash
    1110   00110  1  00  0001   0000   000100100010
    ```

    第二条指令的编码格式是:

    ![](6.png)

    这条指令中cond为1110  为无条件执行，imm4为0001 è 0x1 Rd为0表示r0寄存器，imm12为000100100010 è 0x122 组合而成imm16 = imm4:imm12 为0x3344

    从上面可以看出arm模式下的指令前四位表示的都为执行条件判断，紧接着一般是指令的硬编码，用来区分不同的指令，然后跟着的是指令的寄存器操作数或者是寄存器等。

2. 隐式操作寄存器

    arm指令集中没有隐式操作寄存器的指令，比如在x86中push pop指令在指令中虽然不存在rsp寄存器，但是在指令执行后，会默认移动rsp寄存器，而在arm中没有这样的指令，相同功能的指令表示为push {r0} è STR R0,[SP,#-4]!  , pop {r0}è LDR  R0,[SP, #4]!

3. 条件判断

    在x86指令集中，一般只有条件跳转会使用到标志位，用于分支跳转，而且arm指令集中，arm模式下的指令前四个位都为执行条件判断，都会使用到标志位。

    下图为x86指令集中的条件判断:

    ![](7.png)

    下图为arm指令集中的条件判断:

    ![](8.png)

    在x86指令集中rflags寄存器和arm指令集中PSR寄存器中eflags寄存器中的CF、ZF、SF、OF标志位分别对应arm中的C、Z、N、V,分别为进位借位标志位（无符号数使用）、0标志位、正负标志位、和溢出标志位（有符号数使用），其中x86的CF标志位和arm中的C标志位有区别，在x86中不论加减法，借位进位为1，不借位为0，在arm中 对于加法，如果产生进位，则C=1;否则C=0，对于减法如果产生借位，则C=0;否则C=1。即x86和arm中加法对CF、C标志位的影响相同，减法对其影响相反。

    ![](9.png)

    ![](10.png)

    所以上面的区别导致了x86指令集中的ja成立条件为(CF or ZF) = 0,而在arm指令集中相同的无符号整型HI成立条件C == 1 and Z == 0两者不同，同理x86指令集中的jbe与arm指令集中对应的LS的条件也是不相同的。

---

文章内容大部分来自：

**Arm Architecture Reference Manual for A-profile architecture**
**Intel® 64 and IA-32 Architectures Software Developer’s Manual**
**学习过程中还有很多不足，还望朋友们指正！**
