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



## 参考
1. Effective Java
