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

## 参考
1. Effective Java
