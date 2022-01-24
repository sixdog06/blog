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

## Item 11: Always override hashCode when you override equals
重写`equals`之后必须重写`hashCode`, 参见`hashCode`的契约, 来自Java8的文档.
- Whenever it is invoked on the same object more than once during an execution of a Java application, the hashCode method must consistently return the same integer, provided no information used in equals comparisons on the object is modified. This integer need not remain consistent from one execution of an application to another execution of the same application.
- If two objects are equal according to the equals(Object) method, then calling the hashCode method on each of the two objects must produce the same integer result.
- **It is not required** that if two objects are unequal according to the equals(Object) method, then calling the hashCode method on each of the two objects must produce distinct integer results. However, the programmer should be aware that producing distinct integer results for unequal objects may improve the performance of hash tables.

> significant field: 影响比较条件的字段

如果不重写, 那么像`HashMap`这种依赖hashCode的类就会出现问题. 而计算哈希值也有一个三部曲:
1. 定义一个名为`result`的`int`字段, 初始化为第一个significant field算出的哈希值
2. 对每个significant field, 做以下计算

- 基础类型的字段f, 计算`Type.hashCode(f)`. 
- 引用类型字段, 如果是`equals`中是递归地调用`equals`去一层一层比较, 那么`hashCode`也同样递归计算. 如果计算过于复杂, 需要对这个字段设置一个canonical representation来计算hashCode, 如果这个字段是null, 用默认值代替, 这个默认值通常是0. 
- 数组字段, 若没有significant element, 用**非0常数**代替, 如果全是significant element, 直接调用`Arrays.hashCode`来计算, 而如果只有部分是significant element, 用`Type.hashCode(f)`计算每一个值, 并用算出来的每一个c做`result = 31 * result + c`计算, 得到哈希值

对于这个计算公式中31的选择, 主要因为它是一个奇数. 如果是个偶数, 在做乘法时如果结果超出了数据范围的限制, 那么信息会丢失, 因为从位运算的角度看, 乘2相当于左移一位. 而`31 * i == (i << 5) - i`, 虚拟机会优化为位运算获得更好的性能表现. 写哈希方法时, 不要给计算方法的详细说明, 因为这会限制以后的优化. 像`String/Integer`的hashCode都是根据实例计算的确定值, 造成以后所有的新发布都要依赖这种实现.

## Item 12: Always override toString
如果不重写, 返回的是`类名@hashCode的十六进制`. 书中推荐对所有可以实例化的类都重写`toString()`方法, 言下之意, 对静态工厂类, 枚举类没必要重写

## Item 13: Override clone judiciously(todo)
`Cloneable`这个接口起一个标记的作用, 如果有类实现了它, 当其对象`clone`方法被调用时, 会返回对象的copy, 对象的每个字段都应该被copy. 所以如果要实现这个接口, 类应该提供一个通常实现起来很复杂的`clone`方法. 

## Item 14: Consider implementing Comparable
实现`compareTo`后便可以用`Arrays.sort(a);`或者有自动排序功能的Collection如TreeSet. 
```
public interface Comparable<T> {
    int compareTo(T var1);
}
```

Comparable的契约: Compares this object with the specified object for order. Returns a negative integer, zero, or a positive integer as this object is less than, equal to, or greater than the specified object. Throws ClassCastException if the specified object’s type prevents it from being compared to this object. 一般用-1, 1代替负值和正值, 负值正值的绝对值要相等. 满足reflexivity, symmetry, and transitivity. 还有一点, 推荐但不强制`(x.compareTo(y) == 0) == (x.equals(y))`, 行为一致会让代码清晰, 不一致应指明他们的相等条件的维度是什么(natural ordering?/other kinds of ordering?). 像BigDecimal的equals和compareTo的实现就是不同的, 对于`new BigDecimal("1.0") and new BigDecimal("1.00")`如果用HashSet这种基于`equals`的集合去存储, 两个都会存进去, 而对于TreeSet这种基于`compareTo`的集合, 会被认为是相等的. 比较时还要注意越界的问题, 不要用`Integer-Integer`这种方式最为return的值



## 参考
1. Effective Java