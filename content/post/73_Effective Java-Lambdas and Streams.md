---
title: "Effective Java-Enums and Annotations"
date: 2021-12-28
draft: false
author: "小拳头"
categories: ["Java"]
---

这是Effective Java第七章的总结, 讲Lambdas和Streams这两个在Java8中经常使用的特性. 项目链接[JavaLab](https://github.com/huanruiz/JavaLab).

## Item 42: Prefer lambdas to anonymous classes
对匿名类, 可以用lambda简化写法. lambda的限制是只能替换函数式对象/不能保证序列化和反序列化的正确性, 还有一点, 如果lambda写的过长, 也会影响可读性.

# Item 43: Prefer method references to lambdas
灵活运用method references和lambdas, 哪个写法可读性高用哪个, 我自己使用中大多数情况还是prefer method references, 因为可以一下就定位执行方法的来源是哪个类. 书中总结了如下五种可以来回替换的类型. 
| Method Ref Type | Example | Lambda Equivalent |
| -- | -- | -- |
| Static | Integer::parseInt | str -> Integer.parseInt(str) |
| Bound | Instant.now()::isAfter| Instant then = Instant.now(); t -> then.isAfter(t) |
| Unbound | String::toLowerCase | str -> str.toLowerCase() |
| Class Constructor | TreeMap<K,V>::new | () -> new TreeMap<K,V> |
| Array Constructor | int[]::new | len -> new int[len] |

## Item 44: Favor the use of standard functional interfaces
有了函数式编程的加持, 写api的时候就可以用各种`functional interfaces`. 大多数情况下不用子基写, 直接使用`java.util.function`包中的就ok. 6个基本的函数式接口如下. 他们都有int/long/double的版本, 方法名就是前缀加数据类型. 具体使用时看包下有哪些接口最直观. 
| Interface | Function Signature | Example |
| -- | -- | -- |
| UnaryOperator<T> | T apply(T t) | String::toLowerCase |
| BinaryOperator<T> | T apply(T t1, T t2) | BigInteger::add |
| Predicate<T> | boolean test(T t) | Collection::isEmpty |
| Function<T,R> | R apply(T t) | Arrays::asList |
| Supplier<T> | T get() | Instant::now |
| Consumer<T> | void accept(T t) | System.out::println |

## Item 45: Use streams judiciously
streams和写循环需要trade off, streams让代码短了, 但是可读性可能差了, 通过一定的helper method可以帮助提升可读性. 因为stream过程中的值是拿不到的, 会对debug造成困扰(虽然idea有stream debug工具). 书中列举了几个stream用起来很舒适的场景:
- Uniformly transform sequences of elements
- Filter sequences of elements
- Combine sequences of elements using a single operation(for example to add them, concatenate them, or compute their minimum)
- Accumulate sequences of elements into a collection, perhaps grouping them by some common attribute
- Search a sequence of elements for an element satisfying some criterion

## Item 46: Prefer side-effect-free functions in streams
对同一个逻辑, 虽然可以写不同的stream实现, 但是要记住我们是在用函数式编程的思想. 比如`forEach`方法应该是用来展示stream的结果, 而不是用来在stream中计算, 我们需要的是一个stream的输入输出, 而不是过程中每个元素的行为. 除此之外书中介绍了`toList/toSet/toMap/groupingBy/joining`, 其中[toMap有个坑](https://huanruiz.github.io/post/72_java%E4%B8%ADtomap%E4%B8%8Easlist%E7%9A%84%E5%9D%91/), 在书中也介绍了.

## Item 47: Prefer Collection to Stream as a return type
在Java8, Stream和Iterator的相互转换不是容易的事情. 所以当我们写的返回返回一个sequence时, 最好用Collection的实现, 这样在使用的地方既可以用stream处理, 也可以用for-each处理. Collection的限制是`size()`的返回值是int, 所以这个方法最大只能返回`Integer.MAX_VALUE`, 当然具体能不能存超过这个值的数字, 还是要看具体的实现.

## Item 48: Use caution when making streams parallel


## 参考
1. Effective Java
