---
title: "Effective Java Chapter8-Methods"
date: 2022-01-17
draft: false
author: "小拳头"
categories: ["学习笔记"]
tags: ["Java"]
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
varargs容易出现因为输入参数不确定而导致的错误, 比如传参为空等等. 优化方式是overload同名方法, 用多参数方法替换, 以`public void foo(int a1, int a2, int a3, int... rest)`结尾. 但这会造成方法过多, 所以依然要trade-off优劣.

## Item 54: Return empty collections or arrays, not nulls
如标题所讲, 不要再返回集合或数组时返回null, 而是用长度为0的集合或数组代替. 集合有类似`Collections.emptyList()`这样的方法,减少对性能的影响. 数组也可以被定义长度为0的空数组.

## Item 55: Return optionals judiciously
`Optional<T>`的作用是用来**返回一个值**, 并且防止这个值的返回是null而作额外的处理. 但是它的使用是受限的
- 不要用来封装collections, maps, streams, arrays这样的集合, 因为他们本身可以有空的返回
- 有`OptionalInt, OptionalLong, OptionalDouble`这三个类, 所以`int, long, double`类型就直接使用这三个类包装即可
- key, value, collection, array都不适合用optional作为元素

## Item 56: Write doc comments for all exposed API elements
个人觉得看这一章不如直接看JDK的jar包中的注解, 比如Collection系列注解, String注解和其他常用类/接口的注解. 
