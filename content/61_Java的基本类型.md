---
title: "Java的基本类型"
date: 2021-08-06
draft: false
toc: true
categories: ["Java"]
---

在刚结束的培训项目中需要把几个指标落库, 我想当然的以为int那21亿的范围应该已经够用了, 结果发现一堆out of range. 发现我实际上并对最最基本的数据类型理解不深入, 而这却是开发天天都会打交道的东西, 于是花了点时间了解了基础的数据类型. 

Java的基础类型有8种, 包括4种整型, 2种浮点类型, 和Unicode的char, 与boolean. 
| 类型 | 位数 |	字节 | 默认值 |
|  ---   | --- | --- |  ---  |
| int | 32 | 4 | 0 |
| short	| 16 | 2 | 0 |
| long	| 64 | 8 | 0L |
| byte	| 8 | 1	| 0 |
| char	| 16 | 2 | 'u0000' |
| float	| 32 | 4 | 0f |
| double | 64 |	8 |	0d |
| boolean | 1 |		| false |

## 位运算
todo


## 整型与浮点数转换


## 包装类


## 参考
1. Java核心技术卷1
2. [Java基础知识](https://github.com/Snailclimb/JavaGuide/blob/master/docs/java/basis/Java%E5%9F%BA%E7%A1%80%E7%9F%A5%E8%AF%86.md#%E5%9F%BA%E6%9C%AC%E6%95%B0%E6%8D%AE%E7%B1%BB%E5%9E%8B)
3. [The Java Tutorials - Variables](https://docs.oracle.com/javase/tutorial/java/nutsandbolts/variables.html)