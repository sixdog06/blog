---
title: "Effective Java-General Programming&Exceptions"
date: 2022-01-20
draft: false
author: "小拳头"
categories: ["Java"]
---

这是Effective Java第九和第十章的总结, 讲如何编程. 项目链接[JavaLab](https://github.com/huanruiz/JavaLab).

## Item 57: Minimize the scope of local variables
减少局部变量的scope, 比如循环遍历Iterator的场景, 大多数人都会用while遍历, 这样会在循环的外部创建Iterator, 容易导致错误使用Iterator. 如果是for-loop, 在for的括号内定义Iterator, 就避免了这种问题.

## Item 58: Prefer for-each loops to traditional for loops
为了防止溢出, 用for-each替代传统的for loop. 除了以下三点无法使用for-each的场景
- Destructive filtering: 需要移除集合中的元素, 但是这个时候可以考虑用`Collection’s removeIf`
- Transforming: 需要遍历集合替换集合中的元素
- Parallel iteration: 并行地遍历多个集合

## Item 59: Know and use the libraries
别造轮子, 在理解的基础上多用库里有的api. 比如Java8中的随机数可以用性能更好的`ThreadLocalRandom`和`SplittableRandom`提供的api实现, 而不是用Random本身. 

## Item 60: Avoid float and double if exact answers
因为浮点型天然无法准确表示negative power of ten, 所以在需要精确计算(货币计算)时不能使用. 可以使用`BigDecimal`替换, 带来的问题是比较麻烦, 而且计算会比浮点型更慢. 还有一个办法就是用更小的单位, 这样就可以用整型来表示浮点型.

## Item 61: Prefer primitive types to boxed primitives
用基本数据类型, 省去拆箱装箱和乱用包装类型导致bug的烦恼. 虽然在泛型的场景, 我们不得不用包装类型.

## Item 62: Avoid strings where other types are more appropriate


## 参考
1. Effective Java