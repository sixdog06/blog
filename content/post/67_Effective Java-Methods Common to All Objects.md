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
- Consistent: For any non-null reference values x and y, multiple invocations of x.equals(y) must consistently return true or consistently return false, provided no information used in equals comparisons is modified. 对unreliable resources应该不写equals, 否则很难满足`Consistent`, 比如`java.net.URL`的equals会比较ip, 但ip会因为路由变动
- Non-nullity: For any non-null reference value x, x.equals(null) must return false. 

书上总结了高质量`equals`方法四部曲:
1. 用`==`检查输入是否是现在对象的引用, 是的话不用比了
2. 用`instanceof`检查输入的类型是否正确
3. 在`instanceof`为`true`的基础上强制转换类型
4. 比较字段是否相同, 基本类型用`==`比较, 包装类型用`Float.compare(float, float)`/`Double.compare(double, double)`比较, 一些可为空的对象, 可用`Objects.equals(Object, Object)`比较. 

除了四部曲之外, 有几点要注意. 我们可以用AutoValue框架来自动生成equals, 我认为自动生成不仅仅只是为了方便, 还可以让我们double check自己写的代码是否有问题.
- 重写`equals`后必须重写`hashCode`
- 注意`equals`的入参是Object而不是具体的类
- 写相等条件的时候, 只比较想要比较的条件, 这种条件是符合需求的即可, 而不是把所有字段一层一层往下比

## 参考
1. Effective Java