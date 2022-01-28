---
title: "Effective Java Chapter9&10-General Programming&Exceptions"
date: 2022-01-20
draft: false
author: "小拳头"
categories: ["Java"]
---

这是Effective Java第九和第十章的总结, 讲如何编程. 项目链接[JavaLab](https://github.com/huanruiz/JavaLab).

## Item 57: Minimize the scope of local variables
减少局部变量的scope, 比如循环遍历Iterator的场景, 大多数人都会用while遍历, 这样会在循环的外部创建Iterator, 容易导致错误使用Iterator. 如果是for-loop, 在for的括号内定义Iterator, 就避免了这种问题.

## Item 58: Prefer for-each loops to traditional for loops
为了防止溢出, 用for-each替代传统的for loop. 除了以下三点无法使用for-each的场景
- Destructive filtering: 需要移除集合中的元素, 但是这个时候可以考虑用`Collection’s removeIf`
- Transforming: 需要遍历集合替换集合中的元素
- Parallel iteration: 并行地遍历多个集合

## Item 59: Know and use the libraries
别造轮子, 在理解的基础上多用库里有的api. 比如Java8中的随机数可以用性能更好的`ThreadLocalRandom`和`SplittableRandom`提供的api实现, 而不是用Random本身. 

## Item 60: Avoid float and double if exact answers
因为浮点型天然无法准确表示negative power of ten, 所以在需要精确计算(货币计算)时不能使用. 可以使用`BigDecimal`替换, 带来的问题是比较麻烦, 而且计算会比浮点型更慢. 还有一个办法就是用更小的单位, 这样就可以用整型来表示浮点型.

## Item 61: Prefer primitive types to boxed primitives
用基本数据类型, 省去拆箱装箱和乱用包装类型导致bug的烦恼. 虽然在泛型的场景, 我们不得不用包装类型.

## Item 62: Avoid strings where other types are more appropriate
能不用String的场景尽量用其他的类型替换, 书中介绍了一些case, 在开发中常见的场景就是redis key, 如果用String魔法值表示很容易重复. 如果转而用枚举表示, 并用String作为枚举的一个字段不失为一个更好的方式.

## Item 63: Beware the performance of string concatenation
因为`String`是immutable的, 所以用`+`拼接需要把原来的多个String全部赋值一遍, 产生不必要的内存消耗. 用`StringBuilder`可以避免这一点.

## Item 64: Refer to objects by their interfaces
为了代码的灵活度, 引用对象的时候最好用合适的接口去表示引用. 有3中情况不好用接口表示:
1. `String`或`BigInteger`这种本身不会有多种实现类
2. 没有合适的接口使用, 像class-based framework, 类的粒度已经最大了
3. 类里面有的方法咋接口没有提供, 如`PriorityQueue`的`comparator`在`Queue`接口中没有

## Item 65: Prefer interfaces to reflection
当我们需要的类在编译期才能确定时, 只能通过反射实现. 反射问题主要有三个: 编译期的检查没了/写起来麻烦/性能比正常new对象差. 我们使用反射的时候应当在new的时候就做好, 并用接口或父类去引用实例. 在使用时就当普通的实例使用即可.

## Item 66: Use native methods judiciously
为了安全, native methods别用, 相信JVM...

## Item 67: Optimize judiciously
不要傻乎乎地优化性能, 试着写好代码而不是写快速的代码, 好的代码自然快. 对底层设计, 从算法和数据结构上就要考虑性能, 并且要有灵活度, 让我们在以后的升级中能有更多操作空间.

## Item 68: Adhere to generally accepted naming conventions
列几个特点:
- 可实例化的**Class**通常由单数名词/名词词组组成, 而不可实例化的Class通常是复数名词
- **接口名**和类名相似, 或在后缀加上able/ible表能力
- **方法名**表示一种操作, 由动词/动词词组组成, 返回`boolean`的方法会有is前缀. 除了JavaBean中的方法, 注意与getter和setter区分(不用get/set做前缀)
- **转换类型的方法**, 一般是`toType`的形式. **返回基础类型的方法**, 一般是`typeValue`的形式. 

---

下面开始第10章的笔记, 讲exceptions.

## Item 69: Use exceptions only for exceptional conditions
exceptions只能用来处理潜在的意外情况, 而不是用作基础的流程控制.

## Item 70: Use checked exceptions for recoverable conditions and runtime exceptions for programming errors
包括Exception及其子类(除了RuntimeException及其子类)都应捕获, 这种类型的异常称为Checked Exception. 包括Error及其子类, RuntimeException及其子类不需要捕获. 但实际上为了项目不崩, 项目一般最后都会有兜底的Exception.

## Item 71: Avoid unnecessary use of checked exceptions
如果某个case会provide insufficient information, 才抛checked exception, 其他情况可以正常走业务逻辑, 用正常代码去拦可能错误的case. 如果unchecked exceptions可以自恢复, 也可以考虑cache但不抛. (日志该记还是要记)

## Item 72: Favor the use of standard exceptions
**Do not reuse Exception, RuntimeException, Throwable, or Error directly**. 把他们当成抽象类, 开发中尽量用标准库的exceptions. 其中`IllegalStateException`是输入的任何只都无效, 其余情况用`IllegalStateException`.
| Exception | Occasion for Use |
| --- | --- |
| IllegalArgumentException | Non-null parameter value is inappropriate |
| IllegalStateException | Object state is inappropriate for method invocation |
| NullPointerException | Parameter value is null where prohibited |
| IndexOutOfBoundsException | Index parameter value is out of range |
| ConcurrentModificationException | Concurrent modification of an object has been detected where it is prohibited |
| UnsupportedOperationException | Object does not support method |

## Item 73: Throw exceptions appropriate to the abstraction
在higher layers去catch lower-level exceptions, 并抛higher-level exceptions, 传递错误信息, 这里主要的目的是防止报错的来源被污染了. 实际开发中通常会catch之后直接记日志, 并隔离lower-level exceptions, 防止影响主业务流程.

## Item 74: Document all exceptions thrown by each method
`throws exception`只抛checked exceptions, 并在`@throw`中做好文档, 如果一个类有很多重复的exception, 那么可以把这个文档写在类的文档中.

## Item 75: Include failure-capture information in detail messages
报错打印足够的信息, 比如`IndexOutOfBoundsException`可以打印出具体上下限是多少, 但注意有信安风险的信息不能打印.

## Item 76: Strive for failure atomicity


## 参考
1. Effective Java