---
title: "Effective Java-Enums and Annotations"
date: 2021-12-28
draft: false
author: "小拳头"
categories: ["Java"]
---

这是Effective Java第六章的总结, 讲枚举类和注解. 项目链接[JavaLab](https://github.com/huanruiz/JavaLab).

## Item 34: Use enums instead of int constants
当需要int常量(static final int)时, 考虑用枚举类. 考虑到枚举类的toString, 可以直接`==`等特点, 更加易用. 又是我们会想用switch来区分枚举类, 这个时候要考虑到扩展性, 如果新添加了新的枚举, 会不会被switch逻辑误导. 同样的, 像`Operation`这种枚举类如果只有加减乘除, 我们要限制扩展, 那个就可以只用switch来判断枚举类型, 除此之外就认为是无效的情况. 

## Item 35: Use instance fields instead of ordinals
用字段代替`ordinal`方法, 否则依赖这个方法的枚举无法自由交换顺序, 新加枚举也会受限. 这个方法是给`EnumSet`/`EnumMap`这样的基于枚举的方法用的, 除了这个用途我们都应该尽量避免使用这个方法.

## Item 36: Use EnumSet instead of bit fields
没有必要用`public static final int STYLE_BOLD = 1 << 0;`这种bit的形式来表示不同的类型. 将其改为直接用枚举表示, 并用EnumSet来表示不同类型的或操作即可. 或操作在bit的形式下就是取集合的目的, 在有枚举类的的情况下显然用枚举可以带来更多的灵活度.

## Item 37: Use EnumMap instead of ordinal indexing
当遇到一个枚举类与属于这个枚举类的类型时一对多的关系, 应该用Map来表示这种关系, 而不是用数组中的序数表示. 最优的方法是用`EnumMap`去表示映射关系, 把多个类型作为stream再`groupingBy`.

## Item 38: Emulate extensible enums with interfaces
因为枚举类本身不能被继承, 所以可以通过写一个通用的接口, 让这个接口定义枚举的通用方法, 去实现可扩展的场景.

## Item 39: Prefer annotations to naming patterns
早先有通过naming patterns(方法名)来捕获某种行为, 现在都用注解了. 书中介绍了`@Test`注解, 并用反射去捕获某个类中被`@Test`注解的方法, 并调用这些方法, 简而言之就是自己写了一个mini的ut测试工具.

## Item 40: Consistently use the Override annotation


## 参考
1. Effective Java
