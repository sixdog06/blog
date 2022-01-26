---
title: "JVM入门-JVM与Java体系结构"
date: 2021-01-25
draft: false
author: "小拳头"
categories: ["Java"]
tags: ["JVM"]
---

Java的垃圾回收使得开发效率大大提升(对比C++), 但是理解JVM工作机制才能更好地让我们我们有扩展知识和debug的能力. JVM不一定只是支持Java的, 不同的编程语言通过编译器转化成遵从JMV规范的**字节码文件**, 都可以被解释运行.

**JVM是程序虚拟机**, 而VMware属于系统虚拟机. 是二进制字节码的运行环境. 可以一次编译到处运行, 有自动内存管理, 自动垃圾回收功能. 主要结构如下图:
![](/30_1.png)

一般来说第一次编译是把源文件编译成字节码文件, 第二次是把字节码文件中的字节指令编译成机器指令, 并把机器指令缓存起来, 放在方法区中. JIT编译器可以通过这种方式提高性能.
![](/30_2.png)

**Java编译器输入的指令流基本上是一种基于栈的指令集架构**, 跨平台型好, 指令集小, 编译器容易实现. 基于寄存器的指令集指令较少.

**JVM的生命周期**包含启动(通过bootstrap class loader创建initial class), 执行(执行Java虚拟机的**进程**), 退出(正常结束, 异常或错误导致终止, 调用了Runtime类或System类exit()方法, 或Runtime类halt()方法结束了进程).

JVM有很多种, 现在在用的一般就是HotSpot, 顾名思义它具有热点代码探测技术. 国内还有阿里开发的AliJVM.

## 参考
1. [尚硅谷最新版宋红康JVM教程](https://www.bilibili.com/video/BV1PJ411n7xZ?p=1)
2. [The Java® Virtual Machine Specification](https://docs.oracle.com/javase/specs/jvms/se8/html/index.html)