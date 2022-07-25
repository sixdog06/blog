---
title: "JVM入门-方法区"
date: 2021-01-28
draft: false
author: "小拳头"
categories: ["学习笔记"]
tags: ["JVM"]
---

所有的方法区在逻辑上属于堆的一部分(官方文档原话), 但一些简单的实现可能不会选择去进行垃圾收集或者进行压缩. 所以我们把方法区看作是一块独立于Java堆的内存空间. 本质上方法区和永久代(元空间)不等价, 但是在HotSpot我们认为他们相同. 要注意元空间不再虚拟机设置的内存中, 而是使用本地内存(依然会有OOM的问题).
![](/34_1.png)
![](/34_2.png)

# 方法区
方法区(Method Area)与Java堆一样, 是各个线程共享的内存区域; 方法区在JVM启动时就会被创建, 并且它的实际的物理内存空间中和Java堆区一样都可以是不连续的; 方法区选择固定大小或者拓展; 方法区的大小决定了系统可以保存多少个类, 太多的类会导致方法区溢出, 虚拟机会抛出内存溢出错误java.lang.OutOfMemoryError: PermGen space或java.lang.OutOfMemoryError: Metaspace; 关闭JVM就会释放这个区域的内存.

## 设置大小与OOM
### jdk7及以前:
1. 通过-XX:PermSize来设置永久代初始分配空间. 默认值是20.75M
2. -XX:MaxPermSize来设定永久代最大可分配空间, 2位机器默认是64M, 64位机器模式是82M
3. 当JVM加载的类信息容量超过了这个值，会报异常OutOfMemoryError: PermGen space

### jdk8及以后:
1. 元数据区大小可以使用参数-XX:MetaspaceSize和-XX:MaxMetaspaceSize.
2. 默认值依赖于平台.
3. windows下, MetaspaceSize是21M, MaxMetaspaceSize的值是-1, 无限制.
4. 对于一个64位的服务器端JVM, 默认MetaspaceSize值为21MB.这就是初始的高水位线，一旦触及这个水位线, Full GC将会被触发并卸载没用的类(类加载器不在存活), 然后重置高水位线. 新的高水位线的值取决于GC后释放了多少元空间. 如果释放的空间不足, 那么在不超过MaxMetaspaceSize时, 适当提高该值, 如果释放空间过多, 则适当降低该值. 所以为了避免频繁地GC, 最好给MetaspaceSize大一点的值.

## OOM
1. 要解决OOM异常或heap space的异常, 一般的手段是通过内存映像分析工具(Eclipse Memory Analyzer)对dump出来的堆转储快照进行分析, 确认内存中的对象是否是必要的，区分是出现了内存泄漏(Memory Leak)还是内存溢出(Memory 0verflow).
2. 如果是内存泄漏, 进一步通过工具查看泄漏对象到GC Roots的引用链, 找到泄漏对象是通过怎样的路径与GCRoots相关联并导致垃圾收集器无法自动回收它们的, 定位出泄漏代码的位置.
3. 如果不存在内存泄漏, 那么就是内存中的对象确实都还必须存活着, 那就应当检查虚拟机的堆参数(-Xmx与-Xms)与机器物理内存对比看是否还可以调大, 从代码上检查是否存在某些对象生命周期过长, 持有状态时间过长的情况, 尝试减少程序运行期的内存消耗.

## 内部结构
方法区存储了已被虚拟机加载的**类型信息**(包括接口枚举注解), **常量**(运行时常量池), **静态变量**, **编译器编译后的代码缓存**, **运行时常量池**. 官方文档概括为: run-time constant pool, field and method data, and the code for methods and constructors. `.class`这个字节码文件(包括哪个加载器)就应该存在在方法区, 而堆放的是new出来的对象本身. 所以我们可以直接反编译`.class`去字节码文件, 去看有哪些被加载到方法区的信息, 但是这个时候不能从字节码中看出来使用的哪个加载器, 因为还没有被加载.
![](/34_4.png)

### 类型信息
对每个加载的类型(Class, Interface, Enum, Annotation), 方法区中存储以下类型信息. 从易于理解的角度来看, ß域信息和方法信息也可以当做类型信息.
1. 这个类型的完整有效名称(包名.类名).
2. 这个类型直接父类的完整有效名.
3. 这个类型的修饰符(public, abstract, final的某个子集).
4. 这个类型直接接口的一个有序列表.

#### 域(成员变量)
JVM必须在方法区中保存类型的所有域的相关信息(域名称, 域类型, 域修饰符)以及域的声明顺序; 

#### 方法信息
1. 方法名称.
2. 方法的返回类型(或void).
3. 顺序记录方法参数的数量和类型.
4. 方法的修饰符(public, private, protected,static, final, synchronized, native, abstract的一个子集).
5. 方法的字节码(bytecodes), 操作数栈, 局部变量表及大小(abstract和native方法除外), 异常表(abstract和native方法除外)每个异常处理的开始位置, 结束位置, 代码处理在程序计数器中的偏移地址, 被捕获的异常类的常量池索引.

### 运行时常量池
字节码文件本身包含一个常量池, 但我们更在意的是**字节码中的常量池加载到方法区之后的运行时常量池**. 一个有效的字节码文件中除了包含类的版本信息, 字段, 方法以及接口等描述信息外, 还包含**常量池表(Constant Pool Table)**, 包括字面量(数量值, 字符串值, 类引用, 字段引用)和方法的**符号引用**. 下面的简单代码用了很多Class, 全部存到字节码是不现实的, 所以需要符号引用, 当需要的时候再加载. 运行时字节码的方法区的井号加数字就对应常量池表的index.
```
Public class Simpleclass {
    public void sayhello() {
        System.out.Println(hello); 
    }
}
```

每个类和接口被加载后, 就会创建对应的运行时常量池. 运行时常量池中包含多种不同的常量, 包括编译期就已经明确的数值字面量, 也包括到运行期解析后才能够获得的方法或者字段引用. 常量池中的符号地址会转换为**真实地址**. 如果创建类或接口的运行时常量池时, 如果构造运行时常量池所需的内存空间超过了方法区所能提供的最大值, 则JVM会报OutOfMemoryError. 运行时常量池是有**动态性**的, 因为字节码常量池中可能没有某个Class, 所以运行时常量池放的东西可能比常量池多.

## non-final的类变量
类变量被类的所有实例所共享, 即使没有类实例也可以访问. 所以如下代码是可以运行的. 这个时候我们可以看没有被加载的`.class`文件, 发现`final static`的常量已经被赋值了, 而只是`static`的类变量没有被赋值, 因为类变量的默认初始化和初始化发生在类加载的阶段.
```
public class MethodAreaTest {
    public static void main(String[] args) {
        Order order = null; //order依然可以用static的变量和方法
        order.hello(); //hello()是静态的
        System.out.println(order.count); //count是静态的
    }
}

class Order {
    public static int count = 1;
    public static final int number = 2;
    public static void hello() {
        System.out.println("hello!");
    }
}
```

## 方法区的使用
下面的代码没有new对象, 不涉及堆空间, 便于观察实验对象1.
```
public class MethodAreaDemo {
    public static void main(String[] args) { //静态方法
        int x = 500;
        int y = 100;
        int a = x / y;
        int b = 50;
        System.out.println(a + b);
    }
}
```
编译过后的在方法区中的字节码指令部分如下.
```
 0 sipush 500 //非static方法0一般是this
 3 istore_1 //把500放入栈帧中的局部变量表, 回忆slot
 4 bipush 100 
 6 istore_2
 7 iload_1 //push进操作数栈
 8 iload_2
 9 idiv //除, 结果入栈
10 istore_3 //5存到本地变量表
11 bipush 50
13 istore 4
15 getstatic #2 //调用System.out, 对应运行时常量池的#2, 这个符号应用在运行时会被转换成直接引用
18 iload_3
19 iload 4 
21 iadd //5 + 55
22 invokevirtual #3 //执行打印操作(虚方法调用)
25 return
```

## 方法区的演进
1. 只有HotSpot才有永久代.
2. Hotspot中方法区的变化如下:
- jdk1.6及之前: 有永久代(permanent generation), 静态变量存放在永久代上.
- jdk1.7: 有永久代, 但已经逐步去除永久代, 其中的字符串常量池/静态变量被转移到堆中.
- jdk1.8及之后: 无永久代, 类型信息, 字段, 方法, 常量保存在本地内存的元空间. 但字符串常量池, 静态变量仍在堆.
![](/34_5.png)
![](/34_6.png)

*为什么jdk1.8要移除永久代呢?* 因为永久代的空间大小是很难确定的. 如果动态加载类过多, 容易产生有永久代的OOM. 比如某个实际Web工程中, 因为功能多, 在运行过程中要不断动态加载很多类, 导致错误出现. 而**元空间在本地内存**中, 只受本地内存限制(MaxMetaspaceSize的值是-1); 并且调优永久代比较困难. 

*为什么StringTable要调整位置呢?* jdk7中将StringTable放到了堆空间中, 因为永久代的回收效率很低, 在full gc的时候才会触发. 而full GC只有老年代的空间不足或者永久代空间不足时才会触发. 这就导致了StringTable回收效率不高. 所以放到堆里可以及时回收内存, 增加了效率.

## 方法区垃圾回收
方法区内常量池之中主要存放的两大类常量: 字面量和符号引用. 字面量比较接近Java语言层次的常量概念, 如文本字符串, 被声明为final的常量值等. 而符号引用则属于编译原理方面的概念, 包括类和接口的全限定名, 字段的名称和描述符和方法的名称和描述符. 

- HotSpot虚拟机对常量池的回收策略很明确, 只要常量池中的常量没有被任何地方引用, 就可以被回收. 
- 类则需要判断是否该类所有的实例都已经被回收, 也就是Java堆中不存在该类及其任何派生子类的实例/加载该类的类加载器已经被回收/该类对应的java.lang.Class对象没有在任何地方被引用, 无法在任何地方通过反射访问该类的方法. Java虛拟机**被允许**对满足上述三个条件的无用类进行回收, 但是不是一定会回收. 

整个运行时数据区就可以总结为这张图:
![](/34_7.png)

## 参考
1. [尚硅谷最新版宋红康JVM教程](https://www.bilibili.com/video/BV1PJ411n7xZ?p=1)
2. [The Java® Virtual Machine Specification](https://docs.oracle.com/javase/specs/jvms/se8/html/index.html)