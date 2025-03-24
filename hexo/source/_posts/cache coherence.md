---
title: cache coherence
sticky: false
comments: true
toc: true
toc_number: true
mathjax: true
highlight_shrink: false
aside: true
copyright: false
date: 2025-01-18 12:00:00
updated:
tags: system
categories:
keywords:
description:
cover: 2.svg
top_img: /media/14.jpg
copyright_author:
copyright_author_href:
copyright_url:
copyright_info:
---


### 背景
缓存一致性（cache coherence）是指在多核系统中不同缓存中的数据的一致性和同步性问题

这里有一个例子可以比较清晰的反应这个问题，如下图所示，在Time1时，core1的private cache读取了共享存储中的A值，此时A为42，在Time2时core2也读取了共享存储中的变量A的值，还是为42，接着在Time3时，core1将A的值从42增加为43，此时core2的private cache中A的值还是为42，这时就需要一个协议一种方法来维护private cache中变量，来防止在变量被修改时，其他private cache中的变量数据没有被及时更新

![](1.png)

下图是cpu的多级缓存结构，在L0和L1cache之间会产生cache coherence的问题，之所以会产生这样的问题，是由于多核在读一个变量时，当中产生了一个或多个写操作，需要同步给其他core，显而易见的是，如果只存在都，不存在写，就不需要同步
![](2.svg)

## cache到memory的数据更新关系
### 从缓存和内存间的数据更新关系来看
- 写回（write back）对缓存的修改不会立刻传播到内存，只有在当前的cache line被替换或者是其他的cache line发起写请求时，cache line需要把新数据跟新到memory

- 写直达（write through）想cache line中写新数据时，立刻把新数据更新到memory，让cache line和memory中的数据保持一致

### 从写缓存，core之间的更新策略来看
- 写更新（write update）每次缓存写入新的值，这个core需要发起一次总线请求，通知其他core更新他们cache line的数据

- 写无效（write invalidate）每次缓存写入新的数据，都将其他核对应的cache line置为无效

### 从写缓存的时间来看
- 写分配（write allocate）数据没有在cache line中存在过，cache line中新加入的数据


## MESI协议
维护这样状态最经典常用的协议就是MESI协议
### 这个协议将cache line中的数据分为四个状态分别是：
- M(modified) cache line中的数据被修改，和memory中的数据不同，这个时候cache line也是属于独占状态，可以理解为独占dirty状态
- E(Exclusive) cache line中的数据只存在于当前cache line和memory中，没有其他拷贝，是属于独占状态且没有被修改过，是独占clean状态
- S(shared) cache line中的数据同时存在多份拷贝，数据是clean
- I(invalid) cache line中的数据是无效的

### 在MESI协议中对事件的定义如下：
处理器cache line的请求：
- PrRD: core请求读cache line中的数据
- PrWr: core请求修改cache line中的数据

### 总线对cache line的请求：
- BusRd: bus总线收到来自其他core需要读cache line的请求
- BusRdX：bus总线收到另一个core需要读一个其不拥有的缓存块的请求
- BusUpgr：bus总线收到core需要写一个其拥有的cache line的请求
- Flush: bus总线收到core需要把cache line的数据写回memory的过程
- FlushOpt： bus总线收到一个core需要把自己cache line的数据同步给所有的其他核的cache line以及memory

### 状态机
![](3.png)



根据状态机，大致分析可以简单得到多核同时存在一条数据备份，且有一个core需要发起写请求时，其他核心的状态可能是：
![](4.svg)
由上图可视，当一个core发起对一个数据的写请求时，这个数据当在其他core中也存在时，有8中可能存在的场景，接下来对这8中场景进行解析
#### 当发起读请求的core中的cache line状态为invalid，其他core中状态为modified时
![](cacheline_0.svg)
1. core 0 向bus总线发送写信号
2. core 1 将modified的数据更新到memory并将状态设置为valid
3. core 0 从memory中读取数据
4. 修改core 0 cache line中的数据并将cache line的状态设置为modified

#### 当发起读请求的core中的cache line状态为invalid，其他core中状态为exclusive时
![](cacheline_1.svg)
1. core 0 向bus总线发送写信号
2. core 1 将cache line状态设置为invalid
3. core 0 从memory中读取数据
4. 修改core 0 cache line中的数据并将cache line的状态设置为modified

#### 当发起读请求的core中的cache line状态为invalid，其他core中状态为shared时
![](cacheline_2.svg)
1. core 0 向bus总线发送写信号
2. 所有shared的core的cache line状态都置为invalid
3. core 0 从memory中读取数据
4. 修改core 0 cache line中的数据并将cache line的状态设置为modified

#### 当发起读请求的core中的cache line状态为invalid，其他core中状态也为invalid时
![](cacheline_3.svg)
1. core 0 向bus总线发送写信号
2. core 0 从memory中读取数据
3. 修改core 0 cache line中的数据并将cache line的状态设置为modified

#### 当发起读请求的core中的cache line状态为shared，其他core中状态也为shared时
![](cacheline_4.svg)
1. core 0 向bus总线发送写信号
2. 其他core将cache line状态置为invalid
3. 修改core 0 cache line中的数据并将cache line的状态设置为modified

剩下的情况是发起写请求的状态为ME，其他核中cache line状态为invalid，这时直接修改将cache line状态修改为modified即可，因为ME都是cache line独占状态，只不过是M是dirty cache line，E是clean cache line


## 参考资料
[知乎：缓存一致性协议\(cache coherence\)学习](https://zhuanlan.zhihu.com/p/702405106)
[A Primer on Memory Consistency and Cache Coherence](https://link.springer.com/book/10.1007/978-3-031-01764-3)
[Computer Systems: A Programmer's Perspective](https://csapp.cs.cmu.edu/)
