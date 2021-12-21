---
title: "Effective Java-Generics"
date: 2021-12-14
draft: false
author: "小拳头"
categories: ["Java"]
---

这是Effective Java第五章的总结, 讲泛型. 项目链接[JavaLab](https://github.com/huanruiz/JavaLab).

## Item 26: Don’t use raw types
在集合中不要用`raw types`, 写集合带钻石符号, 避免在runtime时期程序出错. 但是因为泛型擦除, 有几个地方是例外:
1. 用`List.class`, `String[].class`, `int.class`等class literals
2. 用instanceof验证类型时, 如`o instanceof Set`

## Item 27: Eliminate unchecked warnings
书中提醒我们要干掉所有warning, 有些是因为代码的疏忽造成的, 还有一些warning是编译器抛出但是我们可忽略的. 对可以忽略的warning, 可以加上`@SuppressWarnings("unchecked")`注解, 注意**要把这个注解的范围缩到最小**. 对于一些不好加注解的语句, 比如`return`, 可以把return的值定义出来, 并在定义的代码上加入此注解.

## Item 28: Prefer lists to arrays
和上一节一样, list支持泛型, 让我们从编译期就能看到代码的错误, 如果使用array, 一些类型转换/不同类型赋值的场景就很有可能出错. 这种把数据聚集起来的情况, 我们多数情况都要竟可能让元素统一. 

## Item 29: Favor generic types
这一节结合了上面几节, 把非泛型的Stack类改造成了泛型Stack类, 除此之外, 还有个释放obsolete reference的小细节. 跟着敲一遍!

## Item 30: Favor generic methods
和用泛型类一样, 用泛型方法可以避免类型转换带来的问题, 书中循序渐进总结了从非泛型方法转换泛型方法, 泛型单例工厂, 

## Item 31: Use bounded wildcards to increase API flexibility


## 参考
1. Effective Java
