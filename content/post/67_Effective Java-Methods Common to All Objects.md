---
title: "Effective Java-Methods Common to All Objects"
date: 2021-11-16
draft: false
author: "小拳头"
categories: ["Java"]
---

这是Effective Java第三章的总结, 将如何override Object类的方法, 以及`Comparable.compareTo`这个类似的方法. 项目链接[JavaLab](https://github.com/huanruiz/JavaLab).

## Item 10: Obey the general contract when overriding equals
最简单的办法就是不去重写`equals`方法, 这意味着每个实例只与自己相等. 那么这个类通常满足以下5种情况.
1. 每个类是独立的, 如`Thread`, 类本身并没有value这种概念
2. 这个类没有必要提供"logical equality" test. 比如`java.util.regex.Pattern`可以去重写`equals`来表示两个实例有同样的正则表达式, 但是没有这种必要
3. 父类已经重写了`equals`, 并且`equals`适用于子类
4. 这个类是private or package-private的, 并且`equals`不会被调用. 为防止调用, 可以像工厂类的私有构造器那样, 手动在`equals`中`throw new AssertionError()`, 设计上这个并不是必须的.
5. 单例的类, 例如枚举类

而表示值的类通常需要重写equals. 重写equals需要满足**Reflexive, Symmetric, Transitive, Consistent**4个基本条件和一个空处理条件. 
- Reflexive: For any non-null reference value x, x.equals(x) must return true.
- Symmetric: For any non-null reference values x and y, x.equals(y)must return true if and only if y.equals(x) returns true.
- Transitive: For any non-null reference values x, y, z, if x.equals(y) returns true and y.equals(z) returns true, then x.equals(z) must return true.
- Consistent: For any non-null reference values x and y, multiple invocations of x.equals(y) must consistently return true or consistently return false, provided no information used in equals comparisons is modified.
- For any non-null reference value x, x.equals(null) must return false.

## 参考
1. Effective Java