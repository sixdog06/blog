---
title: "Java的基本类型"
date: 2021-08-08
draft: false
author: "小拳头"
categories: ["学习笔记"]
tags: ["Java"]
---

在刚结束的培训项目中需要把几个指标落库, 我想当然的以为int那21亿的范围应该已经够用了, 结果项目发布后报了一堆out of range. 我发现自己对最最基本的数据类型理解不深入, 而这却是开发天天都会打交道的东西, 于是花了点时间了解了基础的数据类型. 基于Java8.

Java的基础类型有8种, 包括4种整型, 2种浮点类型, 和Unicode的char, 与boolean. 命名的时候只能以字母/`_`/`$`开头, 但是为了可读性, 开发时永远不要用`_`和`$`开头, 并保持驼峰式命名. 定值用全大写, 并用下划线分开其中的单词. (这些命名规则都是卸载Java官方文档的原话)
| Data Type | #bits | Default Value(for fields) |
| --- | --- | --- |
| byte | 8 | 0 |
| short | 16 | 0 |
| int | 32 | 0 |
| long | 64 | 0L |
| float | 32 | 0.0f |
| double | 64 | 0.0d |
| char | 16 | '\u0000' |
| boolean | 未知 | false |

## 存储原理
### 整型
Java的整型都是**2的补码**这种类型的整型, 所以整型的范围是$2^{bits - 1}$. 对于byte/short, 通常会用在比较长的数组中, 这个时候不同的数据类型, 对空间的影响就会很大. 而大多数时候都会用int, 当int范围不够时就需要用long了. int和long在Java8及以后再包装类中支持无符号方法, 但是在我们直接初始化整型的时候, 还是没法用类似C语言那样直接写`unsigned int a = 1;`, 所以大多数情况下都忽略这个无符号的情况.

原码就是在书之前增加了一位符号位, 而正数的原码/反码/补码相同, 负数的反码就是原码除符号位取反, 补码是其反码加1. 用8位byte举例, 如果原码是`00001000`, 那么就代表10进制的8. 它的补码是反码加1, 也就是$11110111 + 00000001 = 11111000$. 而`11111000`就代表10进制的-8. 这种方式下, 8与-8做加法, 就相当于 $00001000 + 11111000 = 100000000$, 最高位溢出, 去掉后结果就是0. 这样使得正负数计算都可以简单地运用一套加法规则. 换个角度看, 我们也就明白了为什么`0b10000000`支持的是-128, 而不是127, 因为最高位是符号位, 实际上只有7位是真正的数值位.

> 注意long在初始化的时候, 数字结尾要加L, 而float初始化结尾加f. 是因为JVM在存储时整型和boolean默认是用int存储, 而浮点型用double存储. 

### 浮点型(todo)
Java的浮点数遵循**IEEE-754**标准, float最大支持正负`3.40e38`(有效位数6~7位), double最大支撑正负`1.79x10308`(有效位数15位). 浮点型虽然范围大, 但是是不精确的, 业务中涉及的精确计算需要用`BigDecimal`实现. 浮点数运算在除数为0时不报错, 但是会返回`NaN`/`Infinity`/`-Infinity`, 在debug的时候遇到这种值就能立刻定位程序的问题在哪里.

有时候我们还回涉及浮点型转换整型, 这个过程实际上就是直接丢弃小数部分, 如果转型后的数字依然超过了整型的最大范围, 那么整型就会取其范围所在的最大值.

## 包装类
每一种基本类型都对应了包装类, 在我们写`Integer a = 1;`/`int b = a;`的时候回自动得在编译阶段装箱拆箱, 对应`Integer.valueOf()`/`Integer.intValue()`方法. 
| Data Type | Wrapper Class |
| --- | --- |
| byte | java.lang.Byte |
| short | java.lang.Short | 
| int | java.lang.Integer |
| long | java.lang.Long |
| float | java.lang.Float |
| double | java.lang.Double |
| char | java.lang.Character |
| boolean | java.lang.Boolean |

包装类比较时必须用`equals`方法, 因为我们不知道比较的值是由常量池产生或是new的新对象.

## 参考 
1. [JavaGuide - Java基础知识](https://github.com/Snailclimb/JavaGuide/blob/master/docs/java/basis/Java%E5%9F%BA%E7%A1%80%E7%9F%A5%E8%AF%86.md#%E5%9F%BA%E6%9C%AC%E6%95%B0%E6%8D%AE%E7%B1%BB%E5%9E%8B)
2. [The Java Tutorials - Variables](https://docs.oracle.com/javase/tutorial/java/nutsandbolts/variables.html)
3. [关于2的补码](https://www.ruanyifeng.com/blog/2009/08/twos_complement.html)