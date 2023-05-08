---
title: "JVM入门-对象实例化与直接内存"
date: 2021-01-28
draft: false
author: "小拳头"
categories: ["学习笔记"]
tags: ["JVM"]
---

运行时方法区已经讲完了, 那么new的对象是在堆中的, 它的类信息在方法区, 而局部变量在虚拟机栈中. 接下来我们梳理的是内存层面对象到底是怎么实例化, 内存布局是怎样的.

## 对象创建
对象创建的方式如下:
![](/35_1.png)

## 创建对象步骤
从字节码角度看, 用如下代码测试.
```
public class ObjectTest {
    public static void main(String[] args) {
        Object obj = new Object();
    }
}
```
```
0: new #2 //加载Object类, 在堆中开辟内存空间(为int, byte等变量), 并对内存初始化
3: dup //栈空间中建立引用
4: invokespecial #1 //调用Object构造器, 如果有参, 就要放在操作数栈中, 并执行static代码块等赋值操作
7: astore_1
8: return
```

可以总结为6步.
1. 首先判断对象对应的类是否加载, 链接, 初始化. 虚拟机遇到一条new指令, 首先去检查这个指令的参数能否在Metaspace的常量池中定位到一个类的符号引用, 并且检查这个符号引用代表的类是否已经被加载, 解析和初始化. 若没有就双亲委派, 使用当前类加载器以ClassLoader+包名+类名为Key进行查找对应的class文件. 如果没有找到文件, 则抛ClassNotFoundException异常, 若找到, 就加载类, 并生成对应的Class类对象.
2. 为对象分配内存. 首先计算对象占用空间大小, 接着在堆中划分一块内存给对象. 如果内存规整, 使用指针碰撞. 如果内存不规整，虚拟机需要维护一个列表, 使用空闲列表分配.
3. 处理并发安全问题(1. CAS失败重试, 区域加锁: 保证指针更新操作的原子性; 2. TLAB把内存分配的动作按照线程划分在不同的空间之中进行, 即每个线程在Java堆中预先分配一小块内存, 称为本地线程分配缓冲区).
4. 初始化分配到的空间. 虚拟机将分配到的内存空间都初始化为零值(除对象头). 这一步保证了对象的实例字段在Java代码中可以不用赋初始值就可以直接使用. 
5. 设置对象的对象头. 将对象的所属类(即类的元数据信息), 对象的HashCode和对象的GC信息, 锁信息等数据存储在对象的对象头中. 这个过程的具体设置方式取决于JVM实现.
6. 执行init方法进行初始化. 初始化成员变量, 执行实例化代码块, 调用类的构造方法, 并把堆内对象的首地址赋值给引用变量.

## 对象的内存布局
![](/35_2.png)

对于代码
```
public class CustomerTest {
    public static void main(String[] args) {
        Customer cust = new Customer();
    }
}

public class Customer {
    int id = 1001;
    String name;
    Account acct;
    {
        name = "匿名客户";
    }
    public Customer() {
        acct = new Account();
    }
}
```
内存空间状态如下: 
![](/35_3.png)

main这个线程的局部变量表就有args和cust(静态变量没有this). 而cust指向堆空间的Customer实例. 类型指针指向了方法区. 

## 对象的访问定位
那么怎么通过栈帧中的对象引用访问到其内部的对象实例的呢?
![](/image/jvm6_4.png)

一般分为**句柄访问**和**直接指针(HotSpot采用)**, 分别为如下两张图. 
![](/35_5.png)
![](/35_6.png)

## 直接内存
直接内存指Java堆外的, 直接向系统申请的内存区间. jdk8后的元空间就是用的直接内存.

**todo**

## 参考
1. [尚硅谷最新版宋红康JVM教程](https://www.bilibili.com/video/BV1PJ411n7xZ?p=1)
2. [The Java® Virtual Machine Specification](https://docs.oracle.com/javase/specs/jvms/se8/html/index.html)
3. [对象创建过程](https://www.cnblogs.com/chenyangyao/p/5296807.html)