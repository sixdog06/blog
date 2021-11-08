---
title: "<Effective Java>Creating and Destroying Objects"
date: 2021-11-08
draft: false
author: "小拳头"
categories: ["Java"]
---

这是Effective Java第二章的总结, 主要涵盖对象的创建和销毁.

## Item1: Consider static factory methods instead of constructors
这个建议和设计模式中的工厂方法不是一个东西, 这里指当我们创建对象的时候, 考虑用静态方法返回一个实例, 而不是通过new的方式直接创建对象. 

好处有
- 方法可以有自己的名字, 不像构造器只能用类名, 防止名字不符合对象本身的意义, 签名也不会=因为参数类型, 参数数量而固定
- 静态工厂方法不会像构造器一样在调用的时候创建新的对象, 像`Boolean.valueOf`返回的是`static final Boolean`
- 可以返回子类型的对象, 比如我们用接口定义一些行为, 返回这些对象不用考虑对象的具体实现
- 放回对象可根据输入不同而不同
- 在写方法的时候, 返回的实例不一定存在(各种service provider framework)

限制有
- 如果类只提供静态工厂方法, 没有public/protected的构造器, 那么没法被继承. 这种类更加推荐composition而不是inheritance
- 开发者找静态工厂方法比直接找构造器难, 所有会有新手用`new`而不是`valueOf`.

## Item 2: Consider a builder when faced with many constructor parameters
用一个静态内部类Builder去替代telescoping constructor, 这个Builder可以替代setter, 让这个类immutable. 

## 参考
1. Effective Java