---
title: "Effective Java-Enums and Annotations"
date: 2021-12-28
draft: false
author: "小拳头"
categories: ["Java"]
---

这是Effective Java第七章的总结, 讲Lambdas和Streams这两个在Java8中经常使用的特性. 项目链接[JavaLab](https://github.com/huanruiz/JavaLab).

## Item 42: Prefer lambdas to anonymous classes
对匿名类, 可以用lambda简化写法. lambda的限制是只能替换函数式对象/不能保证序列化和反序列化的正确性, 还有一点, 如果lambda写的过长, 也会影响可读性.

# Item 43: Prefer method references to lambdas
灵活运用method references和lambdas, 哪个写法可读性高用哪个, 我自己使用中大多数情况还是prefer method references, 因为可以一下就定位执行方法的来源是哪个类. 书中总结了如下五种可以来回替换的类型. 
| Method Ref Type | Example | Lambda Equivalent |
| -- | -- | -- |
| Static | Integer::parseInt | str -> Integer.parseInt(str) |
| Bound | Instant.now()::isAfter| Instant then = Instant.now(); t -> then.isAfter(t) |
| Unbound | String::toLowerCase | str -> str.toLowerCase() |
| Class Constructor | TreeMap<K,V>::new | () -> new TreeMap<K,V> |
| Array Constructor | int[]::new | len -> new int[len] |

## Item 44: Favor the use of standard functional interfaces


## 参考
1. Effective Java
