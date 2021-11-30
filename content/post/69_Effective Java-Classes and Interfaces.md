---
title: "Effective Java-Classes and Interfaces"
date: 2021-11-28
draft: false
author: "小拳头"
categories: ["Java"]
---

这是Effective Java第四章的总结, 讲如何设计Java Class和Interfaces, 这是我们写Java去抽象逻辑的核心. 项目链接[JavaLab](https://github.com/huanruiz/JavaLab).

## Item 15: Minimize the accessibility of classes and members
尽量让类的accessibility严格, 书中讲了很多原因, 总的来说就是降低代码的耦合度, 对private的方法, 我们可以放心地优化/修改. 对于类的字段, 大多数情况都不应该让他们是public的. 对于`public static final fields`常量, 应该用大写+下划线的格式命名.

这里要注意nonzero-length array, 即使是`public static final Thing[]`, 其中的值可以被修改. 我们可以让这个字段`private`, 然后露出一个返回或者它的方法/用另一个字段返回一个只读的copy.

## 参考
1. Effective Java