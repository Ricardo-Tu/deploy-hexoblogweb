---
title: cache replacement policy
sticky: false
comments: true
toc: true
toc_number: true
mathjax: true
highlight_shrink: false
aside: true
copyright: false
date: 2025-01-04 12:00:00
updated:
tags: system
categories:
keywords:
description:
cover: 3.png
top_img: /media/16.jpg
copyright_author:
copyright_author_href:
copyright_url:
copyright_info:
---


## 概述
### 背景
- 如何评价一个cache系统的performance

    $$
    \begin{aligned}
    CPU_{time} 
    &= IC * (Alu_{Ops} / Inst * CPI_{AluOps} + (MemOps / Inst) * AMAT) * CycleTime \\
    &= IC * CPI * CycleTime
    \end{aligned}
    $$


`IC`: Instruction count，需要执行指令的数量
`CPI`: Cycles Per Instruction,每条指令执行的平均时长
`CycleTime`: 芯片一个周期的时间，提高主频降低每个周期的时间


- Average Memory Access Time(AMAT)
    $$
    \begin{aligned}
    AMAT 
    &= HitRate * HitTime + MissRate * MissPenalty \\
    &= HitRate * HitTime_{inst} + MissRate_{inst} * MissPenalty_{inst} + HitTime_{data} + MissRate_{data} * MissPenalty_{data}
    \end{aligned}
    $$

- cache hit-rate/miss-rate: s/r
Where s is the number of memory requests serviced by the cache and r is the total number of memory requests made to the cache.
s的定义是一个访存请求到cache，cache能立刻返回请求的概率，r是访存请求发起的总次数

根据一篇[paper](https://www.researchgate.net/publication/220771820_High_performance_cache_replacement_using_re-reference_interval_prediction_RRIP)中所述，SRRIP和DRRIP比LRU性能平均高出4%和10%，所需要的硬件比LRU少两倍

### replacement policy的作用
提高cache的性能，提升cache的hit-rate
- 增加cache大小
- 增加cache关联度
- 优化cache replacement policy算法

降低miss-penalty
- 多级cache设计

减少hit-time
- 简化cache设计
- 并行访问cache
- 增加cache访问流水级


### replacement policy操作流程
![](1.png)

`insertion policy`: 当插入新的数据到cache line中，初始化cache line状态的策略
`promotion policy`: 当hit cache时，promotion policy
`aging policy`: 当cache line大小不足时，插入和promotion有冲突时所采用的策略
`eviction policy`: eviction出那一条cache line的策略

### 常见高速缓存访问模式
![](2.png)

`Recency-friendly Accesss Pattern`: 类似于堆栈先进后出的数据序列，对于这种序列，数据的重引用是及时的LRU算法对于这样的序列有最大的优化，其他的算法都会降低对这种数据序列访问的性能
`Thrashing Access Pattern`: 对于一个相同的序列循环重复访问N次，序列的宽度大于cache size，如果小于等于，任何算法对于这样的优化都是相同的，当k>cache size时，LRU算法对这种数据序列没有任何优化
`Streaming Access Pattern`: 无限不循环序列，任何replacement policy都不会有优化
`Mixed Access Pattern`: 上图中举出了两个例子，第一个例子可分成两个部分理解，第一部分是a1到ak的一个Recency-frinedly Access Pattern序列，接着是一个a1到am的列表序列，然后会对列表中的任意数量的项做访问或修改。第二条例子类似，只是第一部分是Thrashing access pattern，对于第二种混合序列当m+k小于可用cache size，LRU运行良好

## SRRIP算法介绍
![](3.png)
本文只介绍了SRRIP算法，这个图是参考资料中的paper中截图，文章中举例讲了三种算法，我们这里解析这三种算法，对于这三种算法，都读取了相同的序列[a1,a2,a2,a1,b1,b2,b3,b4,a1,a2]，下面解析每行结尾的小括号中时cache中数据链表的数据存储情况。接下来的解释纯属个人理解，可能会有错误，如有错误，欢迎指出，我也能够改正

### 对于LRU算法
1. 读a1时，cache为空，miss，将a1写入cache链的head (a1)
2. 读a2时，cache中没有a2，miss，将a2写入cache链的head，a1在a2的后面 (a2 -> a1)
3. 读a2时，cache中有a2，hit，此时a2在cache链的head，不用调整链的节点顺序 (a2 -> a1)
4. 读a1时，cache中有a1，hit，此时a1不在链的head，将a1的节点提到链表首 (a1 -> a2)
5. 读b1时，cache中没有b1，miss，将b1插入链表head (b1 -> a1 -> a2)
6. 读b2时，cache中没有b2，miss，将b2插入链表head (b2 -> b1 -> a1 -> a2)
7. 读b3时，cache中没有b3，miss，将b3插入链表head，此时链表节点已经达到最大4，将tail的a2删除 (b3 -> b2 -> b1 -> a1)
8. 读b4时，cache中没有b4，miss，将b4插入链表head，此时链表节点已经达到最大4，将tail的a1删除 (b4 -> b3 -> b2 -> b1)
9. 读a1时，cache中没有a1，miss，将a1插入链表head，此时链表节点已经达到最大4，将tail的b1删除 (a1 -> b4 -> b3 -> b2)
10. 读a2时，cache中没有a2，miss，将a2插入链表head，此时链表节点已经达到最大4，将tail的b2删除 (a2 -> a1 -> b4 -> b3)

### 对于NRU算法
对于每一个cache增加了一个nru bit，新加入cache这个bit都初始化为0
1. 读a1时，cache为空，miss，按顺序将a1写入cache (a1)
2. 读a2时，cache中没有a2，miss，按顺序将a1写入cache (a1 -> a2)
3. 读a2时，cache中有a2，hit，和LRU相比，这里hit不会将hit节点提到链表首 (a1 -> a2)
4. 读a1时，cache中有a1，hit，和LRU相比，这里hit不会将hit节点提到链表首 (a1 -> a2)
5. 读b1时，cache中没有b1，miss，按顺序将b1写入cache (a1 -> a2 -> b1)
6. 读b2时，cache中没有b2，miss，按顺序将b2写入cache (a1 -> a2 -> b1 -> b2)
7. 读b3时，cache中没有b3，miss，且cache已满，这时候从左到右按顺序搜索是否存在nru标志为1的cache，如果没有，将所有的nru标志位设置为1，然后从左到右找到第一个nru bit为1的cache替换 (b3 -> a2 -> b1 -> b2)
8. 读b4时，cache中没有b4，miss，将b4插入链表head，这时候从左到右按顺序搜索是否存在nru标志为1的cache，搜索到第一个替换 (b3 -> b4 -> b1 -> b2)
9. 读a1时，cache中没有a1，miss，将a1插入链表head，此时链表节点已经达到最大4，将tail的b1删除 (b3 -> b4 -> a1 -> b2)
10. 读a2时，cache中没有a2，miss，将a2插入链表head，此时链表节点已经达到最大4，将tail的b2删除 (b3 -> b4 -> a1 -> a2)


### 对于SRRIP算法
对于每一个cache line增加了M bit的RRPV flag，对于不同的情况，这个M位默认可以设置成不同的数值，在这里这个M为2，所以对于每个cache line，这个RRPV的取值为[0,1,2,3]，这里默认当新数据写入cache会被设置为2，如果RRPV为3，则会被替代
1. 读a1时，cache为空，miss，按顺序将a1写入cache，并设置a1 cache的RRPV flag为2 (a1) RRPV为(2)
2. 读a2时，cache中没有a2，miss，按顺序将a1写入cache，并设置a2 cache的RRPV flag为2 (a1 -> a2) RRPV为(2 -> 2)
3. 读a2时，cache中有a2，hit，和LRU相比，这里hit不会将hit节点提到链表首，这里a2命中会被promotion，将这条cache line的RRPV设置为0 (a1 -> a2) RRPV为(2 -> 0)
4. 读a1时，cache中有a1，hit，和LRU相比，这里hit不会将hit节点提到链表首，这里a1命中会被promotion，将这条cache line的RRPV设置为0 (a1 -> a2) RRPV为(0 -> 0)
5. 读b1时，cache中没有b1，miss，按顺序将b1写入cache (a1 -> a2 -> b1) RRPV为(0 -> 0 -> 2)
6. 读b2时，cache中没有b2，miss，按顺序将b2写入cache (a1 -> a2 -> b1 -> b2) RRPV为(0 -> 0 -> 2 -> 2)
7. 读b3时，cache中没有b3，miss，且cache已满，这时候会查看是否存在RRPV为3的cache，如果没有，这里进行一个Aging，将cache中所有RRPV加1，这时候a1 -> a2 -> b1 -> b2的RRPV分别为 1 -> 1 -> 3 ->3，这时候可以采用其他算法，从RRPV是3的选cache被替换，这里猜测应该用了类似LRU的算法， 被替换的b1比b2存在时间更长，所以b3替换了b1且设置RRPV为2 (a1 -> a2 -> b3 -> b2) RRPV为(1 -> 1 -> 2 -> 3)
8. 读b4时，cache中没有b4，miss，将b4插入链表head，这时候搜索时候发存在RRPV为3的cache，搜索到多个则使用算法选择一个替换，这里b2的RRPV为3，则b4替换b2 (a1 -> a2 -> b3 -> b4) RRPV为(1 -> 1 -> 2 -> 2)
9. 读a1时，cache中存在a1，hit，这里和LRU和NRU都miss，a1又被promotion (a1 -> a2 -> b3 -> b4) RRPV为(0 -> 1 -> 2 -> 2)
10. 读a2时，cache中存在a2，hit，这里和LRU和NRU都miss，a2又被promotion (a1 -> a2 -> b3 -> b4) RRPV为(0 -> 0 -> 2 -> 2)


对于SRRIP算法，promotion是为0还是加1对于不同的data类型，应该可以采取不同的策略，这些应该在不同场景下有不同的性能提升，文章中提及的SRRIP对于Thrashing的data类型，相比较LRU有所提升，所以在实际情况中，mixed数据类型中只要存在Thrashing都会有性能上的提升

## 参考资料
[High performance cache replacement using re-reference interval prediction (RRIP)](https://www.researchgate.net/publication/220771820_High_performance_cache_replacement_using_re-reference_interval_prediction_RRIP)
[Cache Replacement Policies](https://www.amazon.sg/Cache-Replacement-Policies-Akanksha-Jain/dp/3031006348)

