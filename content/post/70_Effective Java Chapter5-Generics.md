---
title: "Effective Java Chapter5-Generics"
date: 2021-12-14
draft: false
author: "小拳头"
categories: ["Java"]
---

这是Effective Java第五章的总结, 讲泛型. 项目链接[JavaLab](https://github.com/huanruiz/JavaLab).

## Item 26: Don’t use raw types
在集合中不要用`raw types`, 写集合带钻石符号, 避免在runtime时期程序出错. 但是因为泛型擦除, 有几个地方是例外:
1. 用`List.class`, `String[].class`, `int.class`等class literals
2. 用instanceof验证类型时, 如`o instanceof Set`

## Item 27: Eliminate unchecked warnings
书中提醒我们要干掉所有warning, 有些是因为代码的疏忽造成的, 还有一些warning是编译器抛出但是我们可忽略的. 对可以忽略的warning, 可以加上`@SuppressWarnings("unchecked")`注解, 注意**要把这个注解的范围缩到最小**. 对于一些不好加注解的语句, 比如`return`, 可以把return的值定义出来, 并在定义的代码上加入此注解.

## Item 28: Prefer lists to arrays
和上一节一样, list支持泛型, 让我们从编译期就能看到代码的错误, 如果使用array, 一些类型转换/不同类型赋值的场景就很有可能出错. 这种把数据聚集起来的情况, 我们多数情况都要竟可能让元素统一. 

## Item 29: Favor generic types
这一节结合了上面几节, 把非泛型的Stack类改造成了泛型Stack类, 除此之外, 还有个释放obsolete reference的小细节. 跟着敲一遍!

## Item 30: Favor generic methods
和用泛型类一样, 用泛型方法可以避免类型转换带来的问题, 书中循序渐进总结了从非泛型方法转换泛型方法, 泛型单例工厂, 

## Item 31: Use bounded wildcards to increase API flexibility
用通配符来放开api的限制, 简而言之就是类似如下代码, 定义的是`Iterable<Number>`, 那么即使Integer是Number的子类, `Iterable<Integer>`是无法传入的, 因为`Iterable<Integer>`不是`Iterable<Number>`的子类, 所以需要通配符.
```
public void pushAll(Iterable<E> src) {
    for (E e : src) {
        push(e);
    }
}
```
因为类型擦除的原因, 通配符要满足PECS原则: **PECS stands for producer-extends, consumer-super.**. extends只能读类型`E`而不能写(null除外), consumer只能写类型`E`而不能读(Object除外). 也是因为这一点, 并不是所有的api中的字段都需要用通配符, 像之前的`public static <E> Set<E> union(Set<? extends E> s1, Set<? extends E> s2)`, 返回值就是`Set<E>`, 输入没有必要用通配符.

书中还讲了swap的例子, 讲了入了: **if a type parameter appears only once in a method declaration, replace it with a wildcard**, 我觉得在实际实现的时候, 这个例子`<?>`通配符的可读性没有不用好.

## Item 32: Combine generics and varargs judiciously
编译器在编译期无法推断可变数组的泛型是什么, 从也可能导致运行期出错. generic varargs methods is safe if: 
1. it doesn’t store anything in the varargs parameter array,
2. it doesn’t make the array (or a clone) visible to untrusted code. (Java8中)
为防止warning, 我们通常会打上`SafeVarargs`注解, 在Java8中, 该注解只能打到static methods/final instance methods上, 换言之, 要保证重写的方法也是安全的. 
还有很多情况下, 可变参数的方法可以在套一个list来保证typesafe, 我感觉还是用list替换比较好, 这种tricky的使用方法在项目里面会带来不必要的麻烦.

## Item 33: Consider typesafe heterogeneous containers
因为泛型限制, 在一个container中往往只能放有限类型的Java对象, 而通过把`Class<?>`对象作为Map的key, 就能存放各种各样的对象. 要注意保证传入的实例类型和Class中的类型对上. 

## 参考
1. Effective Java
