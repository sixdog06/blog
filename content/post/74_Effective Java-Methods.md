---
title: "Methods"
date: 2021-01-17
draft: false
author: "小拳头"
categories: ["Java"]
---

这是Effective Java第八章的总结, 讲如何设计方法, 个构造器原则一样, 考虑`usability, robustness, flexibility`. 项目链接[JavaLab](https://github.com/huanruiz/JavaLab).

## Item 49: Check parameters for validity
对方法和构造器的输入做有效性检测. 我在开发中遇到这种情况有时会记个日志, 而如果是接口的请求, 会针对参数返回对应的错误信息. 对埋的很深的逻辑, 通常不太敢直接抛错, 能丢弃数据的逻辑一般就把它丢了.

## Item 50: Make defensive copies when needed
当我们希望一个实例的字段是immutable的时候, 需要把输入和输出的参数都做copy, 防止在调用后被外部恶意修改. 这样会导致new更多的实例, 所以当调用方可被信任的时候, 用文档标注这个class中的元素可能被修改就好(实际上没见过有人这么做).

## Item 51: Design method signatures carefully


## 参考
1. Effective Java