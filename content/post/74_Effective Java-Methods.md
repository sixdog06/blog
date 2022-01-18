---
title: "Effective Java-Methods"
date: 2022-01-17
draft: false
author: "小拳头"
categories: ["Java"]
---

这是Effective Java第八章的总结, 讲如何设计方法, 个构造器原则一样, 考虑`usability, robustness, flexibility`. 项目链接[JavaLab](https://github.com/huanruiz/JavaLab).

## Item 49: Check parameters for validity
对方法和构造器的输入做有效性检测. 我在开发中遇到这种情况有时会记个日志, 而如果是接口的请求, 会针对参数返回对应的错误信息. 对埋的很深的逻辑, 通常不太敢直接抛错, 能丢弃数据的逻辑一般就把它丢了.

## Item 50: Make defensive copies when needed
当我们希望一个实例的字段是immutable的时候, 需要把输入和输出的参数都做copy, 防止在调用后被外部恶意修改. 这样会导致new更多的实例, 所以当调用方可被信任的时候, 用文档标注这个class中的元素可能被修改就好(实际上没见过有人这么做).

## Item 51: Design method signatures carefully
设计函数签名的几个规则:
- Choose method names carefully. 
- Don’t go overboard in providing convenience methods. 别写过多的方法, 会让使用者崩溃.
- Avoid long parameter lists. 书中推荐4个及以下. 把多个输入减少通常有3种方法. 
    1. 拆方法, 但是会造成方法数量的增加; 
    2. 用helper class来聚合输入的参数; 
    3. 结合1和2, 用Builder pattern来
- For parameter types, favor interfaces over classes.
- Prefer two-element enum types to boolean parameters. 这个主要是true和false有实际意义时, 如果像灰度这种打开关闭的逻辑用boolean会更清楚一点

## Item 52: Use overloading judiciously
**overload没有动态根据instance来运行对应方法的效果, 只能用override实现, override才会在运行期动态选择方法.** 重载的方法集合中最好都不要写有相同参数数量的方法, 要设计相同参数数量的方法就换个名字. 如果是构造器(无法改名字), 那么就提供对应的工厂方法. 书中举了很多有趣的例子, 比如List的`boolean remove(Object o);`/`E remove(int index);`, 一个是删除对应的元素, 一个是删除index位置的元素.

## Item 53: Use varargs judiciously


## 参考
1. Effective Java