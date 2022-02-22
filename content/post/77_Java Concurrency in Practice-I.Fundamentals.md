---
title: "Java Concurrency in Practice-I.Fundamentals"
date: 2022-01-29
draft: false
author: "小拳头"
categories: ["Java"]
---

基础知识覆盖了书中的第二章到第五章. 第一章为粗略地介绍, 简单过一下就好, 相信看这本书的人或多或少是了解Java并发编程的. 项目链接[JavaLab](https://github.com/huanruiz/JavaLab), 有示例的代码以类名的形式均标注在小结的最后.

## Chapter2-Thread Safety
### Atomicity
在不同的线程访问一个资源时, 这个资源的状态应该是一致的, 类的行为和应该有的规范完全一致. 我认为简单地说, 就是这个类的功能不管是单线程还是并发, 都是正常的. **所以无状态对象一定安全**, 因为他没有域, 也没有对其他类的域的引用, 计算过程的局部局部都只在栈上的, 没有共享资源, 那么一定安全了. 当这个而无状态类有字段时, 可以用原子变量类, 如`AtomicLong`来保证原子性(读取-修改-写入). 这里要注意, 原子性只针对原子变量本身, 多个原子变量因为不应时序的调用, 不能保证线程安全. *e.g. AtomicTest*.

### Locking
可以用`synchronized(lock) {}`标注同步代码块, 并且这些**内置锁**是可重入的, 也就是说锁的粒度是线程, 线程可以获得自己持有的锁. *e.g. Widgit*. ~从这里可以看出有些地方写`ReentrantLock`和`synchronized`的区别是`synchronized`不可重入~, 这种说法是错的. 只不过用`ReentrantLock`, 我们可以多次手动获取锁, 并且手动解锁. 

### Guarding statewith locks
多个线程共享的变量应该由一个锁来保护, 反之不是多个线程共享的变量无需保护. 锁需要保护必变性条件中的所有涉及的变量, 只保护一个变量是不够的. 即使像Vector类的所有方法都是`synchronized`方法2, 也不能保证如
```
if (!vector.contains(element)) {
    vector.add(element)
}
```
的复合操作原子.

### Liveness and performance
没有使用原子变量类, 也没有对整个方法加锁, 防止持有锁的时间过长. **要注意对于计算时间长的操作不能加锁. 比如i/o操作**. *e.g. CachedFactorizer*;

## Chapter3-Sharing Objects
### Visibility
没有同步机制, 两个线程的执行顺序是无法判断的(因为重排序), 这时候做内存操作很容易出错, 读的值可能是更新前的**失效数据**, 也可能是更新后的, 影响Visibility. *e.g. NoVisibility* 在JavaBean中, 如果要对一个值的get和set进行同步, 那么`synchronized`需要同时加在在getter和setter方法上. **加锁不仅要保证互斥, 也要保证内存可见性.**

> synchronized方法锁的的是`this`实例, 静态synchronized方法锁的是`ClassName.class`实例. 和对方法内部整个代码块加锁的写法是等价的.

失效数据过期了但是这个值也是有之前的某个线程设置的值, 这个是最低安全性的保证(out-of-thin-air-safety). 但是存在例外: 非volatile的64位数值变量(double/long), JVM允许读写操作分为2个高低32位的操作.

volatile提供轻量级的同步机制, 编译器和运行时不会对volatile变量重排序. **volatile值保证可见性, 不像锁一样还能保证原子性.** 只有如下场景用volatile变量:
- 对变量写入不依赖当前值, 且只会有单个线程更新变量的值
- 该变量不会和其他状态变量一起纳入不变性条件
- 访问变量时不需要加锁

### Publication and escape
publish指对象被作用域外的代码使用, 如果不该publish的对象被publish(对象还没构造好时), 就叫escape. 有一种不容易发现的情况就是构造器中new实例的时候, 这个实例被publish时, 构造器内的this也会被隐式地publish, 然而此时构造器可能并没有执行结束. 所以可以用工厂方法返回实例, 防止escape. *e.g. SafeListener ThisEscape*.

### Thread confinement
从代码实现上, 把会共享的变量限制在只能被一个线程用, 那么就不需要synchronization. 如Swing的dispatch线程. 但如果仅从代码去实现thread confinement(ad-hoc thread confinement), 程序会比较脆弱, 像GUI这样的用一个单线程的子系统去实现, 在很多情况下效果会更好. 

volatile变量是thread confinement的一种特殊情况, 因为只要保证单线程写, 那么Visibility是可保证的. Stack confinement同样也能保证thread confinement, 因为局部变量只会在线程的栈中使用, 局部变量只要不溢出, 那么一定线程安全了. *e.g. ThreadConfinementExample.loadTheArk*.

保证thread confinement最标准的实现方法是使用`ThreadLocal`, 使用时可以把它想象成一个Map, 对不同的线程提供对应的值(实际不是这样实现的), 当线程不用这个值了, 这个值就会被GC. 每个set的值在使用的线程都有独立的副本, 在get时也总会返回当前线程设置的最新值. *ThreadConfinementExample.getConnection*

### Immutability
immutable的对象线程安全, 不可变对象需要满足如下几个条件. *e.g. ThreeStooges*.
- 对象创建后其状态不能修改
- 域都是final(String除外, 严格来说不用满足这一点, 但是实现上需要对JMM有深入的理解, 所以自己写代码别这么做). 将不可变的域声明为final是个好习惯. 
- 对象创建期间, this不溢出

当某个变量的读写有竞争条件时, 可以把他们放在一个不可变对象中, 来保证线程安全. *e.g. VolatileCachedFactorizer OneValueCache*. 

### Safe publication
Effectively immutable objects(技术上状态可变, 但是实际上不会对其进行改变)需要安全地publish, 让使用这个对象的线程看到已发布的状态. 书中总结了以下几种方式. 
- 静态初始化函数中初始化一个对象的引用. 因为静态初始化在JVM的初始化阶段进行, JVM保证内部的线程安全
- 将对象引用保存到volatile或AtomicReference对象中
- 将对象引用保存到正确构造对象的final域中
- 将对象引用保存到一个由锁保护的域中

而Mutable objects不仅仅需要safe publication, 还需要线程安全或用锁保护. 而不可变对象因为本身保证了线程安全, 所以可用任何机制发布. 

## Chapter4-Composing Objects
这一章介绍一些组合模式, 让一个类更容易成为线程安全的类.

### Designing a thread-safe class
设计线程安全的类, 需要考虑3个基本要素. *e.g. Counter*.
- 构成对象状态的**所有变量**
- 约束状态变量的**不变性条件**
- 建立对象状态的并发访问管理策略

### Instance confinement
确保一个对象只能有单个线程访问, 封装在对象内部的数据, 可以把数据的访问限制在对象的方法上. *e.g. PersonSet*. 进而想到Java的监视器模式, 用一把内部锁来封装内部的mutable state. *e.g. PrivateLock*.  *e.g. MonitorVehicleTracker*.

### Delegating thread safety
基于委托的车辆追踪器, *DelegatingVehicleTracker*. locations委托给ConcurrentMap保证线程安全. 这个类中只有单个状态. 还有一种情况是一个类需要多个独立且线程安全的状态变量, 那么可以把主类的线程安全委托给这些变量. 但如果这些变量互相有依赖关系, 限制条件(比如一个必须大于另一个). 那么仍然需要加锁. 

如果保证Point的线程安全, 也可以发布Point, *e.g. PublishingVehicleTracker*. 和DelegatingVehicleTracker的区别是这个`SafePoint`是可以改变的, 因为读写的方法都加了锁, 所以还是能保证线程安全. 

### Adding functionality to existing thread-safe classes
第一种方式是在使用端进行加锁, 但是要注意这个锁需要是实例的`this`, 不是`ListHelper`, 否则这个锁是无效的. 这样使用的问题是破坏封装性, 耦合度更高了. *e.g. ListHelper*. 更好的方法是Composition. *e.g. ImprovedList*. 例子中用监视器模式封装了List.

### Documenting synchronization policies
对类的线程安全性应该写文档,  同步策略是什么, 锁保护了哪些变量, 都应该注明. 如果遇到了没有写线程安全的类, 就假设是不是线程安全的.

## Chapter5-Building Blocks
### Problems with synchronized collections
同之前提到过的一样, 同步容器类进行复合操作, 对调用方也可能是线程不安全的. 比如下面的代码. 解决方式是在调用端, 对复合操作加锁, 锁用`list`对象即可. 
```
public static Object getLast(Vector list) {
    int lastIndex = list.size() - 1;
    return list.get(lastIndex);
}

public static void deleteLast(Vector list) {
    int lastIndex = list.size() - 1;
    list.remove(lastIndex);
}
```

即使是现在常用的并发容器类, 也会有复合操作带来的并发问题, 如下代码. 如果我希望带带期间加锁, 可以克隆这个容器, 去迭代副本, 因为副本封闭在单线程内, 保证线程安全. 还应注意如toString, hashCode, equals这样会隐式迭代的操作. *e.g. HiddenIterator*.
```
List<Widget> widgetList = Collections.synchronizedList(new ArrayList<>());
...
// May throw ConcurrentModificationException
for (Widget w : widgetList) {
    doSomething(w);
}
```

### Concurrent collections
用并发容器替代同步容器, 可以极大提高伸缩性并降低风险. 比如使用`ConcurrentHashMap`, 用更细粒度的锁, 并且本身不能被加锁来执行独占访问. 但是size/isEmpty可能发挥的值不准确(在并发场景作用较小).

### Blocking queues and the producer-consumer pattern
阻塞队列可以用来实现生产者-消费者模式. *e.g. FileCrawler Indexer*. 让对象安全地从生产者线程发布到消费者线程, 实现Serial thread confinement(串行的线程封闭). 对象虽然只属于单个对象, 导师们可以通过安全地publish对象来转义所有权. 书里面还介绍了通过Deque实现work stealing, 也就是消费者访问自己的双端队列, 如果完成了工作, 就送其他消费者消费的双端队列末尾秘密地获取工作, 这就是工作密取. 

### Blocking and interruptible methods
线程可能会因为等待i/o操作结束/等待获得一个锁等等而暂停执行, 如果每个方法被阻塞并抛出`InterruptedException`, 说明该方法是一个阻塞方法. 当阻塞方法被调用时, 最好的办法是传递`InterruptedException`给调用者, 包括不捕获异常, 或捕获异常后再次抛出. 如果需要恢复中断(不能抛错的情况), 可以捕获并尝试恢复*e.g. TaskRunnable*.  

### Synchronizers


## 基础
1. Java并发编程实战
2. [廖雪峰Java教程-多线程](https://www.liaoxuefeng.com/wiki/1252599548343744/1255943750561472)
