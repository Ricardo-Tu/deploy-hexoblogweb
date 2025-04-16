---
title: memory consistency model
sticky: false
comments: true
toc: true
toc_number: true
mathjax: true
highlight_shrink: false
aside: true
copyright: false
date: 2025-02-01 12:00:00
updated:
tags: system
categories:
keywords:
description:
cover: 1.png
top_img: /media/11.jpg
copyright_author:
copyright_author_href:
copyright_url:
copyright_info:
---



---
## 背景

### cache coherence和memory consistency的区别
这只是我个人的一点理解，cache coherence指的是多核处理器中每个核心的private cache line的数据的一致性，memory consistency指在多核处理器中，如果操作读写内存中的数据才能保证整个程序流程执行正确，而不会导致程序执行完，数据被随机修改，能产生很多不同的结果，维护程序正确执行而不产生随机记过的这个规则的模型被叫做memory consistency model，这个model贯穿了硬件编译器和程序员的程序开发，这是一套开发规则约定


### message passing
有一个经典的message passing例子，能反映mcm的存在意义，有两个线程分别在core0和core1上运行，两个线程都会读写x和y两个变量，x存储的是数据，y相当于一个flag，程序理想的执行顺序是，首先初始化x和y为0，core0上thread0将x修改为然后再置y这个flag变量为1，然后core1上的thread1读到flag y为1，也就是thread0已经修改完变量x的值，然后读变量x的值，如下图所示
![](1.png)
在时间线上，可以将这个过程抽象为:
![](2.svg)
而保证这个程序能够按照t0,t1,t2,t3的顺序正确执行，，而不是按照他的的顺序执行，就需要对顺序进行约束，让他按照顺序执行，在x86平台上有三种方式，如下
![](3.png)
在aarch64平台下，有四种形式
![](4.png)
上图是对于软件开发程序员来说能看到的约束关系，而对于硬件程序员来说，看到的关系图如下
![](5.png)
这里对应的是message passing x86平台下第三种约束方式，两条蓝线表示po关系，两条红线表示read from关系，a和b是thread0的x=1,y=1两条写内存命令，c和d表示的是thread1两条x=1,y=1的读内存命令，红色的是约束关系


## isa层MCM顺序一致性约束类型
- po(programing order)在同一个thread中操作不同address，按照程序流顺序执行，不能打乱执行顺序
- rf(read from) read from write，发生读取行为之前要进行一次写的行为
- fr(from read) 先发生了一次读，再发生一次写
- co(coherence order) 多个线程对同一个地址多次写，这些写操作之间的关系是co关系，表示优化排序多次写之间的顺序关系
- ca(coherence after) 对于不同thread对同一个地址的读写，表示在执行命令前后再执行coherence同步
- hb(happens before) 不同thread读写不同的address

## 其他同步类型
### packet process fences
在异构平台上，cpu要维护gpu上进程的执行顺序就需要用到packet，这个同步packet时对所有queue都可见的，一般来说只需要在packet header中设置对应的packet类型为barrier_or或者barrier_and类型
![](6.png)
对于这两种packet，packet内容定义格式都为
![](7.png)
图中的completion_signal只是一个64位的地址，是一个句柄

### SC和TSO
对于上述的一致性约定，属于顺序一致性SC（sequential consistency）是属于强一致性，而总存储顺序模型TSO（total store order）是属于内存存储顺序模型，SC是严格的内存一致性模型，是规定了程序的强制执行顺序，这样使所有过程操作虽然是在不同core上执行，但像是串行执行，这大大降低了性能，而TSO是一种放松的存储内存模型，这个模型中引入了一个store buffer组件，这个存储组件介于指令执行单元和cache之间，允许cpu乱序执行一些读写指令，这个store buffer组件能够加快执行硬件单元读cache的速度
![](8.png)

有了这个组件执行单元读写数据可以通过store buffer或者直接读写memory，这也导致了可能变量存储再store buffer的时候，其他core读写memory，这就可能导致数据一致性的问题，这个TSO相对于SC不同点有
1. 添加了storebuffer到memory hierarchy
2. 将读命令分为store buffer读memory 执行单元读store buffer两个部分
3. 需要不同core之间的store buffer的内容保持一致
4. 需要实现一个fence维护读写书顺序

### 幽灵熔断漏洞
![](9.png)
上述例子时在利用缓存的机制漏洞读取信息的一个例子，首先创建一个测试字符集array，这个测试字符集存放了256个需要比对的字符0x00到0xFF,然后有一个sensitive_addr是需要窃取的一个字符，首先确保比对字符集没有刷到cache line中，这样cpu读数据会比读cacheline中的数据慢，然后sensitive_addr中的数据在cacheline中，我们用一个循环去读取array数据中的数据，这当中肯定会有一个byte的数据和sensitive_addr中的数据一样，由于相同的数据在cache line中有，所以读取速度会比其他到memory中读的速度快，这样几句能找到和sensitive_addr存放字符相同的数据

从硬件角度，利用熔断漏洞的图如下
![](10.png)
图中右边core0中的程序读取core1 L1cache line中的数据，会比core0从memory中读数据快

对于这样的攻击，解决方案也很简单，就是在执行之前加入flush刷新cache，结束加入reload刷新cache
![](11.png)

下图是新的攻击方式，我对这个图的理解是，在core0提交新数据到cache line中会遵守类似EMSI协议的cache coherence协议，会发送cohreq同步请求，以及建立cohresp同步链接，core1中的cache line在接受到数据同步请求后读取同步数据并将cache line设置为S状态，这样就同步了其他core中的变量.这只是我的个人理解，不一定正确
![](12.png)
## mcm验证
对于这样复杂的mcm，有一套测试集，叫做litmus test，有很多验证一致性安全的工具
![](13.png)



## 参考资料
[tutorial_slides](https://check.cs.princeton.edu/tutorial_slides/)
[Heterogeneous System Architecture Foundation](https://hsafoundation.com/standards/)
