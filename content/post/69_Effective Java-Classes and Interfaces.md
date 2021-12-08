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

## Item 16: In public classes, use accessor methods, not public fields
对public classes, 用getter和setter来暴露字段, 不要用public字段. 对私有类/嵌套类, 可以用public的字段

## Item 17: Minimize mutability
Java本身提供了许多immutable的类, 比如String/BigInteger/BigDecimal/包装类. 让类immutable, 有5条规则.
1. Don’t provide methods that modify the object’s state
2. Ensure that the class can’t be extended. 声明为`public final`类, 防止被继承
3. Make all fields final. 
4. Make all fields private. 即使对final的基础数据类型字段, immutable objects的引用字段, 也最用方法的方式返回, 为后序的更新留下余地
5. Ensure exclusive access to any mutable components. 因为有些字段是对象, 而对象本身可能回被外部修改

immutable objects有很多优点, 比如线程安全(因为不可修改), 可以被放心地调用. 但是如果每个不同的对象都要new新的对象, 会造成资源地浪费. 总的来说, 也应该尽可能地使用immutable objects, 即使无法做到, 也要尽量让字段private final, 不露出不必要的setter. 甚至我们可以让构造器也是私有的, 通过静态工厂方法返回对象, 进一步增加灵活度.

## Item 18: Favor composition over inheritance
用组合代替继承(这里仅讨论extend, 不讨论implement), 因为继承实际上违反了封装, 跨包的继承往往比较危险. 继承只适用于真正满足**is-a**关系的情况. 这个item用composition-and-forwarding/装饰者的方式解决了继承带来的问题, 强烈建议看例程. Gvava提供了Collection类的方法. 事实上, Java platform libraries也有很多不合理用继承的类, 比如`Stack extend Vector`和`Properties extend Hashtable`, 他们都应该用组合而不是继承.

## Item 19: Design and document for inheritance or else prohibit it
对可被重写的类留下注释, 如item18中的addAll, 要明确他的内部调用了什么.

## Item 20: Prefer interfaces to abstract classes
书中主要还是介绍了接口的灵活度, 我自己的理解是接口更多定义的是行为(method), 所以只有类拥有某个行为, 就可以用接口去抽象. 像java Collection接口下有很多AbstractInterface抽象类, 这种实现方式叫abstract skeletal implementation class, 实现接口这个类型下一部分的行为(method), 没有实现的方法就可以最大限度地让子类去实现, 而不用考虑父类方法. 而且类可恶意实现多个接口, 对于通用的类型, 用接口更加合适(Serializable, Cloneable等等).

## Item 21: Design interfaces for posterity
书中这一节主要是讲写接口的时候要考虑到子类实现是否合适, 想Collection接口的removeIf(是一个default方法), 对Java自己的集合类可以试用, 但是像某些实现了这个接口的第三方集合类(SynchronizedCollection)就不适用.

## Item 22: Use interfaces only to define types
接口作用是用来定义一个type, 而不是其他. 像`java.io.ObjectStreamConstants`这种constant interface pattern的设计师是有问题的. 去实现这个接口的类即使不用某个常量了, 但是为了保证兼容性还是要去实现这个接口, 并且类的所有子类都会不必要地拥有这些常量. 这种常量应该存在于通用的工具类/某个都会使用此常量的类或接口中.

## Item 23: Prefer class hierarchies to tagged classes
tagged class(类的内部用子弹来区分类型)这种类都应该用继承来替换, tagged class实际上就是对类的继承这种性质的一种不好的模仿.

## 参考
1. Effective Java